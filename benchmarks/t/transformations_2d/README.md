# 2D transformations

This benchmark ports the four fixed 2x2 matrix functions in the pinned Python transformations_2d module: scaling, rotation, projection, and the source-specific reflection formula. The module's import-time print calls are omitted.

## Contract

The i64_array_float64 input is [operation, parameter_micro, component], with exactly three values. Component 0 through 3 selects a row-major matrix entry. Operation 0 selects scaling, 1 rotation, 2 projection, and 3 reflection.

For scaling, parameter_micro divided by 1,000,000 is the scaling factor and parameter_micro is bounded to [-1,000,000, 1,000,000]. For the other operations, parameter_micro divided by 1,000,000 is an angle in radians, bounded to [-6,283,185, 6,283,185]. Invalid operations, parameters, components, or input lengths return -1e300. The output tolerance is 1e-12 absolute and relative.

The source formulas are preserved in row-major order. Scaling returns a diagonal matrix. Rotation uses [c, -s, s, c]. Projection uses cs=c*s once and returns [c*c, cs, cs, s*s]. Reflection uses the source-specific [2*c-1, 2*cs, 2*cs, 2*s-1] formula. In both trigonometric cases, c=cos(angle) and s=sin(angle).

The source's doctest uses an angle of 45 radians; that demonstration value is outside this benchmark's bounded angle range and is not a workload case.

## Pinned source and workload

The source is [TheAlgorithms/Python transformations_2d.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/transformations_2d.py) at commit e1a2a8b016001309a73d5fec4818c35cca139795. The workload covers all four operations, row-major component selection, nonzero-angle formulas, parameter boundaries, and malformed inputs. The independent oracle is in benchmarks/transformations_2d_oracle.py.

## Implementations

| Language | Source |
| --- | --- |
| C | c/t/transformations_2d.c |
| C3 | c3/t/transformations_2d.c3 |
| C++ | cpp/t/transformations_2d.cpp |
| Elisa | elisa/t/transformations_2d.elisa |
| Nim | nim/t/transformations_2d.nim |
| Odin | odin/t/transformations_2d.odin |
| Rust | rust/t/transformations_2d.rs |
| V | v/t/transformations_2d.v |
| Zig | zig/t/transformations_2d.zig |
