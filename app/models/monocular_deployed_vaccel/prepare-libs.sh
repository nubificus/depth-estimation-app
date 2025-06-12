#!/bin/bash

set -euo pipefail

print_usage() {
	echo "Usage: $0 <src_dir> <dst_dir> [manifest_path] [--dry-run] [--keep-rpath] [--force]"
	echo
	echo "  src_dir        Source root containing original .so files"
	echo "  dst_dir        Destination directory for patched .so files"
	echo "  manifest_path  Optional output manifest file (default: dst_dir/dlopen_manifest.txt)"
	echo
	echo "Options:"
	echo "  --dry-run      Show what would be done without making changes"
	echo "  --keep-rpath   Preserve existing RPATH and RUNPATH"
	echo "  --force        Overwrite destination files if they already exist"
	exit 1
}

check_requirements() {
	for cmd in readelf patchelf file ldd tsort; do
		if ! command -v "$cmd" &>/dev/null; then
			echo "Error: Required command '$cmd' is not installed." >&2
			exit 1
		fi
	done
}

sanitize_library() {
	local src="$1"
	local dst="$2"
	local rel="$3"

	if [[ -f "$dst" && "$FORCE" = false ]]; then
		echo "Skipping (already exists): $rel (use --force to overwrite)"
		return
	fi

	#if ! file -b "$src" | grep -q '^ELF.*shared object'; then
	#  echo "Skipping non-ELF: $rel"
	#  return
	#fi

	if $DRY_RUN; then
		echo "Would copy $src -> $dst"
		local dst="$src"
	else
		mkdir -p "$(dirname "$dst")"
		cp "$src" "$dst"
	fi

	local base
	base=$(basename "$dst")
	local soname
	soname=$(readelf -d "$dst" 2>/dev/null | grep SONAME |
		sed -E 's/.*Library soname: \[(.*)\]/\1/' || true)

	if [ -z "$soname" ]; then
		echo "No SONAME: $rel -> setting to $base"
		$DRY_RUN || patchelf --set-soname "$base" "$dst"
	elif [ "$soname" != "$base" ]; then
		echo "Fixing SONAME: $rel has '$soname', setting to '$base'"
		$DRY_RUN || patchelf --set-soname "$base" "$dst"
	else
		echo "SONAME OK: $rel"
	fi

	if ! $KEEP_RPATH; then
		if readelf -d "$dst" | grep -q '(RPATH)'; then
			echo "Stripping RPATH: $rel"
			$DRY_RUN || patchelf --remove-rpath "$dst"
		fi
		if readelf -d "$dst" | grep -q '(RUNPATH)'; then
			echo "Stripping RUNPATH: $rel"
			$DRY_RUN || patchelf --remove-rpath "$dst"
		fi
	fi
}

generate_dependency_order() {
	local dst_dir="$1"
	local unsorted=()
	declare -A dep_graph=()

	# Build a lookup map of basename -> relative path for all libs in dst_dir
	declare -A name_to_rel=()
	while IFS= read -r -d '' sofile; do
		rel="${sofile#$dst_dir/}"
		name="$(basename "$sofile")"
		name_to_rel["$name"]="$rel"
	done < <(find "$dst_dir" -type f -name "*.so*" -print0)

	while IFS= read -r -d '' sofile; do
		rel="${sofile#$dst_dir/}"
		unsorted+=("$rel")

		# Parse dependencies including "not found"
		mapfile -t deps < <(ldd "$sofile" 2>/dev/null | awk '
      /=>/ {
        if ($3 == "not") {
          print $1
        } else if ($3 ~ /^\//) {
          print $3
        }
      }
    ')

		for dep in "${deps[@]}"; do
			if [[ "$dep" == "$dst_dir/"* ]]; then
				dep_rel="${dep#$dst_dir/}"
				dep_graph["$rel"]+="$dep_rel"$'\n'
			else
				# dep might be a basename of a missing library inside dst_dir
				dep_base="$(basename "$dep")"
				if [[ -v "name_to_rel[$dep_base]" ]]; then
					dep_graph["$rel"]+="${name_to_rel[$dep_base]}"$'\n'
				fi
			fi
		done
	done < <(find "$dst_dir" -type f -name "*.so*" -print0)

	local tsort_input=""
	for target in "${!dep_graph[@]}"; do
		while IFS= read -r dep; do
			[[ -z $dep ]] && continue
			tsort_input+="$dep $target"$'\n'
		done <<<"${dep_graph[$target]}"
	done

	if [[ -n $tsort_input ]]; then
		tsort_output=$(echo "$tsort_input" | tsort)
		echo "$tsort_output"
	else
		printf "%s\n" "${unsorted[@]}"
	fi
}

main() {
	if [[ $# -lt 2 ]]; then print_usage; fi

	SRC_DIR="$1"
	DST_DIR="$2"
	MANIFEST="${3:-$DST_DIR/dlopen_manifest.txt}"

	shift 2
	DRY_RUN=false
	KEEP_RPATH=false
	FORCE=false

	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run) DRY_RUN=true ;;
		--keep-rpath) KEEP_RPATH=true ;;
		--force) FORCE=true ;;
		*) echo "Unknown option: $1" && exit 1 ;;
		esac
		shift
	done

	[[ -d "$SRC_DIR" ]] || {
		echo "Source dir does not exist: $SRC_DIR" >&2
		exit 1
	}

	if ! $DRY_RUN; then
		mkdir -p "$DST_DIR"
		>"$MANIFEST"
	fi

	echo "Preparing .so files from $SRC_DIR to $DST_DIR"
	echo "Dry run:      $DRY_RUN"
	echo "Strip RPATH:  $(! $KEEP_RPATH && echo yes || echo no)"
	echo "Force overwrite: $FORCE"
	echo

	find "$SRC_DIR" -type f -name "*.so*" | while read -r src; do
		rel="${src#$SRC_DIR/}"
		dst="$DST_DIR/$rel"
		sanitize_library "$src" "$dst" "$rel"
	done

	if ! $DRY_RUN; then
		echo "Generating dependency-aware load order..."
		generate_dependency_order "$DST_DIR" >"$MANIFEST"
		echo "Manifest written to: $MANIFEST"
	else
		echo "Dry-run mode — manifest not written"
	fi
}

check_requirements
main "$@"
