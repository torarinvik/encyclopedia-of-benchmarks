# Radians

Convert an angle from degrees to radians using the pinned Python expression.

## Contract

- The `float64_unary` ABI accepts a finite binary64 degree value in `[-1,000,000, 1,000,000]` and returns binary64 radians.
- Values outside that normalized domain return `-1e300`. Valid results use relative and absolute tolerance `1e-12`.
- The implementation preserves the source operation order `degree / (180 / pi)`.

## Source semantics

This follows the pinned [TheAlgorithms Python `radians.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/radians.py). The benchmark limits input magnitude to a finite range for repeatable workloads; every finite input in that range uses the source formula unchanged.

## Workload

[`workload.json`](workload.json) includes the pinned examples, negative and fractional angles, full rotations, range endpoints, and out-of-range values.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/radians.c`](../../../c/r/radians.c) |
| C3 | [`c3/r/radians.c3`](../../../c3/r/radians.c3) |
| C++ | [`cpp/r/radians.cpp`](../../../cpp/r/radians.cpp) |
| Elisa | [`elisa/r/radians.elisa`](../../../elisa/r/radians.elisa) |
| Nim | [`nim/r/radians.nim`](../../../nim/r/radians.nim) |
| Odin | [`odin/r/radians.odin`](../../../odin/r/radians.odin) |
| Rust | [`rust/r/radians.rs`](../../../rust/r/radians.rs) |
| V | [`v/r/radians.v`](../../../v/r/radians.v) |
| Zig | [`zig/r/radians.zig`](../../../zig/r/radians.zig) |

The package uses the `float64_unary` benchmark ABI.
