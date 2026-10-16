# 3D vector operations

This package ports the numeric operations from the pinned TheAlgorithms/C `vectors_3d.c` source. The source's `vec_3d` fields are C `float`, so finite binary64 ABI inputs are converted to binary32 before each operation and float results are widened back to binary64. The benchmark covers addition, subtraction, dot product, cross product, norm, unit vector, cross-product matrix, and angle.

## Contract

- Input begins with an exact integer operation code followed by vector components. Codes are `0` add, `1` subtract, `2` dot product, `3` cross product, `4` norm, `5` unit vector, `6` cross-product matrix, and `7` angle.
- Unary operations use `[operation, ax, ay, az]`; binary operations use `[operation, ax, ay, az, bx, by, bz]`. Length must match the selected operation exactly.
- Inputs must be finite, and each vector component is bounded to `[-1,000,000, 1,000,000]`. This keeps the source's float products finite while retaining a broad numeric range.
- Success returns the number of output elements: 1 for dot product, norm, or angle; 3 for add, subtract, cross product, or unit vector; and 9 for the row-major cross-product matrix. Output capacity is measured in binary64 elements, with a maximum workspace of 9.
- Invalid operation codes, lengths, or component values return `-1`. A null output pointer or insufficient capacity returns `-2` without writing output.
- The source's behaviors are preserved: `EPSILON` is the C double literal `1e-9`; `unit_vec` returns zero for norms below that threshold and also for vectors whose computed norm is exactly `1.0f` (the source initializes the result to zero and skips filling it in that case); `get_angle` returns NaN when either norm is below `EPSILON`; and its `acos` argument is not clamped. NaN output elements are written as the JSON string `"NaN"` in workload expectations. Inputs remain finite; infinities are not accepted.

The independent oracle is [`benchmarks/vectors_3d_oracle.py`](../../vectors_3d_oracle.py). The workload covers each operation, the exact-unit source defect, near-zero behavior, undefined angles, and malformed operation/input shapes.

Pinned source: [TheAlgorithms/C `vectors_3d.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/geometry/vectors_3d.c) and [`geometry_datatypes.h`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/geometry/geometry_datatypes.h), commit `e5dad3fa8def3726ec850ca66a7f51521f8ad393`.

Build and record with the `float64_slice_io` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm vectors_3d --language c
python3 benchmarks/run_float64_slice_io.py --algorithm vectors_3d
```

| Language | Port |
| --- | --- |
| C | [`c/v/vectors_3d.c`](../../../c/v/vectors_3d.c) |
| C3 | [`c3/v/vectors_3d.c3`](../../../c3/v/vectors_3d.c3) |
| C++ | [`cpp/v/vectors_3d.cpp`](../../../cpp/v/vectors_3d.cpp) |
| Elisa | [`elisa/v/vectors_3d.elisa`](../../../elisa/v/vectors_3d.elisa) |
| Nim | [`nim/v/vectors_3d.nim`](../../../nim/v/vectors_3d.nim) |
| Odin | [`odin/v/vectors_3d.odin`](../../../odin/v/vectors_3d.odin) |
| Rust | [`rust/v/vectors_3d.rs`](../../../rust/v/vectors_3d.rs) |
| V | [`v/v/vectors_3d.v`](../../../v/v/vectors_3d.v) |
| Zig | [`zig/v/vectors_3d.zig`](../../../zig/v/vectors_3d.zig) |
