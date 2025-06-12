# vAccel integration

## Setup

Put the relevant SOL libs in `lib_cpu` and `lib_gpu` accordingly and run:

```bash
bash prepare.sh
```

to generate the sanitized libs + dlopen manifest and build the vAccel SOL
wrapper.

## Usage

The `sol_monocular_vaccel.py` module is a WiP drop-in replacement for
`sol_monocular_example.py`.

To configure vAccel itself use the relevant environment variables.
