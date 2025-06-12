from pathlib import Path

import numpy as np
import vaccel


class sol_monocular:
    def __init__(self, path=".", *, use_gpu=False):
        self._path = Path(path)
        self._use_gpu = use_gpu
        self._session = vaccel.Session()
        self._resource = None
        self._libs = None
        self._parse_lib_manifest()

    def _parse_lib_manifest(self):
        if self._use_gpu:
            lib_path = self._path / "sanitized_lib_gpu"
        else:
            lib_path = self._path / "sanitized_lib_cpu"
        manifest_path = lib_path / "dlopen_manifest.txt"

        with open(manifest_path) as f:
            libs = [lib_path / line.strip() for line in f]
            libs.append(self._path / "libsol-wrapper.so")
        self._libs = libs

    def init(self):
        resource = vaccel.Resource(self._libs, vaccel.ResourceType.LIB)
        resource.register(self._session)
        self._resource = resource

        self._session.exec_with_resource(
            resource,
            "sol_monocular_init_unpack",
        )

    def _prepare_run_args(self, in__input_1, out__0=None, vdims=None):
        if vdims is None:
            vdims = np.ndarray((1), dtype=np.int64)
        if out__0 is None:
            out__0 = np.zeros((1, 256, 256, 1), dtype=np.float32)

        return (in__input_1, out__0, vdims)

    def run(self, in__input_1, out__0=None, vdims=None):
        (in__input_1, out__0, vdims) = self._prepare_run_args(
            in__input_1, out__0, vdims
        )

        in_args = [in__input_1, vdims]
        out_args = [out__0]
        out = self._session.exec_with_resource(
            self._resource,
            "sol_predict_unpack",
            in_args,
            out_args,
        )
        return out[0]

    def __call__(self, args):
        return self.run(*args)

    def set_IO(self, args):
        (in__input_1, out__0, vdims) = self._prepare_run_args(*args)

        in_args = [in__input_1, vdims]
        out_args = [out__0]
        self._session.exec_with_resource(
            self._resource,
            "sol_monocular_set_IO_unpack",
            in_args,
            out_args,
        )

    def set_seed(self, seed):
        c_seed = vaccel._c_types.CInt(seed, "int64_t")
        self._session.exec_with_resource(
            self._resource,
            "sol_monocular_set_seed_unpack",
            [c_seed],
        )

    def optimize(self, level):
        self._session.exec_with_resource(
            self._resource,
            "sol_monocular_optimize_unpack",
            [level],
        )

    def free(self):
        self._session.exec_with_resource(
            self._resource,
            "sol_monocular_free_unpack",
        )


class sol_monocular_gpu(sol_monocular):
    def __init__(self, path="."):
        super().__init__(path, use_gpu=True)
