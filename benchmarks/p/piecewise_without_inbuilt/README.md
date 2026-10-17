# Piecewise activation without built-ins

This benchmark ports the scalar anonymous function `y` from the pinned
MATLAB/Octave [`Piecewise(without inbuilt).m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/machine_learning/Activation%20Functions/Piecewise%28without%20inbuilt%29.m).
Its branches are `0` when `x <= -0.5`, `x` when `-0.5 < x < 0.5`, and `1`
when `x >= 0.5`. The script's plotting and labels are excluded.

The `float64_slice_io` ABI accepts one finite binary64 value `[x]` directly in
the source's units. The valid domain is `[-10, 10]`; values outside it return
`-1`. A successful call writes the single binary64 result and returns `1`. A null or
short output buffer returns `-2`. Input errors take precedence over output
errors, and no error path writes to the output buffer.

[`workload.json`](workload.json) covers both threshold equalities, neighboring
values on each side, domain boundaries, invalid values and input shapes. The
independent oracle is [`piecewise_without_inbuilt_oracle.py`](../../piecewise_without_inbuilt_oracle.py).

## Ports

| Language | Implementation |
| --- | --- |
| C | [`piecewise_without_inbuilt.c`](../../../c/p/piecewise_without_inbuilt.c) |
| C3 | [`piecewise_without_inbuilt.c3`](../../../c3/p/piecewise_without_inbuilt.c3) |
| C++ | [`piecewise_without_inbuilt.cpp`](../../../cpp/p/piecewise_without_inbuilt.cpp) |
| Elisa | [`piecewise_without_inbuilt.elisa`](../../../elisa/p/piecewise_without_inbuilt.elisa) |
| Nim | [`piecewise_without_inbuilt.nim`](../../../nim/p/piecewise_without_inbuilt.nim) |
| Odin | [`piecewise_without_inbuilt.odin`](../../../odin/p/piecewise_without_inbuilt.odin) |
| Rust | [`piecewise_without_inbuilt.rs`](../../../rust/p/piecewise_without_inbuilt.rs) |
| V | [`piecewise_without_inbuilt.v`](../../../v/p/piecewise_without_inbuilt.v) |
| Zig | [`piecewise_without_inbuilt.zig`](../../../zig/p/piecewise_without_inbuilt.zig) |

Build, record, and verify an implementation with the `float64_slice_io` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm piecewise_without_inbuilt --language c
python3 benchmarks/run_float64_slice_io.py --algorithm piecewise_without_inbuilt
python3 benchmarks/verify_float64_slice_io.py --algorithm piecewise_without_inbuilt
```
