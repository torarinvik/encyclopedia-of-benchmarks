# Gauss elimination

This benchmark ports the pinned C console program's dense Gaussian elimination with partial pivoting. The benchmark ABI accepts packed signed 64-bit integers and returns the solution as a byte-output vector of little-endian binary64 values. The C source's `float` work array is retained as binary32; each result is formatted to two decimal places, matching its `printf("%.2f")` output, before encoding.

## Contract

- Input is `[n, A row-major n*n cells, b n cells]`, with `2 <= n <= 8`.
- Every matrix and right-hand-side value is an integer in `[-100, 100]`; dense matrices are allowed.
- At each elimination step, select the first row with the largest absolute pivot-column value, then swap all augmented columns. Ties keep the earlier row, matching the pinned source's strict `max < candidate` comparison.
- Arithmetic uses binary32 intermediates and the source's elimination and back-substitution order. A zero selected pivot or a zero final pivot returns `-1` with no output.
- Malformed or out-of-domain inputs return `-1`; a null or undersized output buffer returns `-2`. Success returns `8*n` bytes.

The bounded integer domain and small dimension keep arithmetic finite and limit precision issues. Output values are exact decimal hundredths encoded as binary64, so the output tolerance is zero. Singular systems are explicitly rejected because the console source otherwise divides by zero and has no defined failure result.

## Pinned source

The source is [TheAlgorithms/C `numerical_methods/gauss_elimination.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/gauss_elimination.c) at `e5dad3fa8def3726ec850ca66a7f51521f8ad393`. It is a console program with a 20-row fixed array; the benchmark removes prompts and caps `n` at 8 for bounded cross-language work.

## Workload and ports

[`workload.json`](workload.json) includes a system requiring a pivot swap, a dense three-variable system, a fractional solution, singular input, malformed values, and output-capacity handling.

| Language | Source |
| --- | --- |
| C | [`c/g/gauss_elimination.c`](../../../c/g/gauss_elimination.c) |
| C3 | [`c3/g/gauss_elimination.c3`](../../../c3/g/gauss_elimination.c3) |
| C++ | [`cpp/g/gauss_elimination.cpp`](../../../cpp/g/gauss_elimination.cpp) |
| Elisa | [`elisa/g/gauss_elimination.elisa`](../../../elisa/g/gauss_elimination.elisa) |
| Nim | [`nim/g/gauss_elimination.nim`](../../../nim/g/gauss_elimination.nim) |
| Odin | [`odin/g/gauss_elimination.odin`](../../../odin/g/gauss_elimination.odin) |
| Rust | [`rust/g/gauss_elimination.rs`](../../../rust/g/gauss_elimination.rs) |
| V | [`v/g/gauss_elimination.v`](../../../v/g/gauss_elimination.v) |
| Zig | [`zig/g/gauss_elimination.zig`](../../../zig/g/gauss_elimination.zig) |
