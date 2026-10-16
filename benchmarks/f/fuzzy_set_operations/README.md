# Fuzzy Set Operations

This benchmark ports the pinned Python membership-vector algorithms: triangular membership and eight fuzzy set operators. The source uses NumPy arrays; the nine benchmark ports use portable scalar arithmetic over a bounded grid and membership vectors.

## Contract

Input is `[operation, n, left, peak, right, grid[n], membership_a[n], membership_b[n]]`. `n` is 1 through 8. Coordinates and membership values are integers in `[0, 1000]`, interpreted as values divided by 1,000.

- Operation `0` evaluates the triangular membership function at each grid point. Require `left <= peak <= right`; both membership vectors are zero. When `left == peak` or `peak == right`, the benchmark preserves the pinned source's shoulder behavior.
- Operations `1` through `8` use zero triangle parameters and a zero grid. They compute, in order: union `max(a,b)`, intersection `min(a,b)`, complement `1-a`, difference `min(a,1-b)`, algebraic sum `a+b-a*b`, algebraic product `a*b`, bounded sum `min(1,a+b)`, and bounded difference `max(0,a+b-1)`.
- Each output membership is binary64, serialized as little-endian bytes. The function returns `8*n`, `-1` for malformed input, or `-2` when output capacity is insufficient.

[`workload.json`](workload.json) covers each operation, degenerate triangular shoulders, boundary memberships, maximum vector length, malformed layouts, and short output capacity. The byte-output runner gets expected values from the independent [`oracle`](../../fuzzy_set_operations_oracle.py).

## Pinned source

[TheAlgorithms/Python `fuzzy_set_operations.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fuzzy_logic/fuzzy_set_operations.py) defines these formulas over sampled membership vectors. Its optional plotting demo is outside the benchmark contract.

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm fuzzy_set_operations --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm fuzzy_set_operations
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/f/fuzzy_set_operations.c`](../../../c/f/fuzzy_set_operations.c) |
| C3 | [`c3/f/fuzzy_set_operations.c3`](../../../c3/f/fuzzy_set_operations.c3) |
| C++ | [`cpp/f/fuzzy_set_operations.cpp`](../../../cpp/f/fuzzy_set_operations.cpp) |
| Elisa | [`elisa/f/fuzzy_set_operations.elisa`](../../../elisa/f/fuzzy_set_operations.elisa) |
| Nim | [`nim/f/fuzzy_set_operations.nim`](../../../nim/f/fuzzy_set_operations.nim) |
| Odin | [`odin/f/fuzzy_set_operations.odin`](../../../odin/f/fuzzy_set_operations.odin) |
| Rust | [`rust/f/fuzzy_set_operations.rs`](../../../rust/f/fuzzy_set_operations.rs) |
| V | [`v/f/fuzzy_set_operations.v`](../../../v/f/fuzzy_set_operations.v) |
| Zig | [`zig/f/fuzzy_set_operations.zig`](../../../zig/f/fuzzy_set_operations.zig) |
