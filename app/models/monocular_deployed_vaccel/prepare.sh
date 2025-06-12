#!/bin/bash

set -euo pipefail

SCRIPTS_DIR=$(cd -- "$(dirname -- "$0")" >/dev/null && pwd -P)
INPUT_CPU_LIB_DIR=lib_cpu
INPUT_GPU_LIB_DIR=lib_gpu
OUTPUT_CPU_LIB_DIR=sanitized_lib_cpu
OUTPUT_GPU_LIB_DIR=sanitized_lib_gpu

compile_sol_wrapper() {
	export LD_RUN_PATH="${LD_RUN_PATH:-}:${INPUT_CPU_LIB_DIR}"
	g++ -std=c++2b -o libsol-wrapper.so sol_wrapper.c \
		-fPIC -shared -Wl,--as-needed \
		$(pkg-config --cflags --libs vaccel) \
		-L"${INPUT_CPU_LIB_DIR}" -lsol_monocular
}

"${SCRIPTS_DIR}"/prepare-libs.sh "${INPUT_CPU_LIB_DIR}" "${OUTPUT_CPU_LIB_DIR}"
"${SCRIPTS_DIR}"/prepare-libs.sh "${INPUT_GPU_LIB_DIR}" "${OUTPUT_GPU_LIB_DIR}"
compile_sol_wrapper
