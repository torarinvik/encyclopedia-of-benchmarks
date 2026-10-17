# 2D rotation matrix

This package ports the pinned Julia `rotation_matrix` function. Given an angle `theta` in radians, it returns the counterclockwise matrix

```text
[ cos(theta)  -sin(theta) ]
[ sin(theta)   cos(theta) ]
```

## Contract

- ABI: `float64_slice_io`. Input is exactly one finite float64 value `[theta]` in `[-1000,1000]` radians.
- Compute `cos(theta)` and `sin(theta)` directly, without angle normalization. Flatten the matrix in row-major order as `[cos(theta), -sin(theta), sin(theta), cos(theta)]`.
- Return the number of output float64 values (4). Invalid framing or an out-of-range/nonfinite angle returns `-1`. A null output pointer or a capacity smaller than four returns `-2` without writing. Workspace is four float64 elements.
- Compare output values with absolute and relative tolerances of `1e-12`.

The pinned Julia function constructs a `Matrix{Float64}` with the conventional row and column entries shown above. The benchmark’s output encoding is explicitly row-major, independent of Julia’s native column-major storage.

## Workload and oracle

[`workload.json`](workload.json) covers zero, positive and negative rotations, common fractional turns, and both angle bounds, along with malformed and out-of-range inputs. The verifier also probes nonfinite angles, a null output pointer, and insufficient output capacity. The independent [oracle](../../rotation_matrix_oracle.py) uses the direct trigonometric formulas.

Pinned source: [TheAlgorithms/Julia `rotation_matrix.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/matrix/rotation_matrix.jl), function `rotation_matrix`.

## Build and verify

Build a port with the `float64_slice_io` ABI, then record and verify it with:

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm rotation_matrix --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm rotation_matrix
python3 benchmarks/verify_float64_slice_io.py --algorithm rotation_matrix
```

## Implementations

| Language | Port |
|---|---|
| C | [`c/r/rotation_matrix.c`](../../../c/r/rotation_matrix.c) |
| C3 | [`c3/r/rotation_matrix.c3`](../../../c3/r/rotation_matrix.c3) |
| C++ | [`cpp/r/rotation_matrix.cpp`](../../../cpp/r/rotation_matrix.cpp) |
| Elisa | [`elisa/r/rotation_matrix.elisa`](../../../elisa/r/rotation_matrix.elisa) |
| Nim | [`nim/r/rotation_matrix.nim`](../../../nim/r/rotation_matrix.nim) |
| Odin | [`odin/r/rotation_matrix.odin`](../../../odin/r/rotation_matrix.odin) |
| Rust | [`rust/r/rotation_matrix.rs`](../../../rust/r/rotation_matrix.rs) |
| V | [`v/r/rotation_matrix.v`](../../../v/r/rotation_matrix.v) |
| Zig | [`zig/r/rotation_matrix.zig`](../../../zig/r/rotation_matrix.zig) |
