# Average absolute deviation

Compute the arithmetic mean of the absolute distances from the input mean. This package preserves the unrounded result returned by the pinned Python implementation.

## Contract

- Input is an array of 1 to 256 signed 32-bit integers, passed through the signed 64-bit array ABI.
- The result is sum(abs(value - mean(values))) / length, returned as binary64. Values are accumulated in input order for the mean and then for the deviations.
- Empty arrays, arrays longer than 256, and values outside signed 32-bit range return -1e300. The Python source raises ValueError for empty input; the finite sentinel keeps invalid cases representable in this benchmark runner.
- The bounds keep the integer sum below binary64's exact-integer limit. The algorithm uses O(n) time and O(1) auxiliary space.

## Source and related algorithms

The pinned [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/average_absolute_deviation.py) returns the unrounded mean absolute deviation for integer lists. The pinned [Julia implementation](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/average_absolute_deviation.jl) rounds to two decimal places and is a distinct source variant; this package follows Python.

## Workload and build

[workload.json](workload.json) covers the pinned examples, a repeating binary fraction, signed 32-bit edges, empty and oversized arrays, and out-of-range values. All nine ports use the i64_array_float64 ABI family.

| Language | Source |
| --- | --- |
| C | [c/average_absolute_deviation.c](../../../c/a/average_absolute_deviation.c) |
| C3 | [c3/average_absolute_deviation.c3](../../../c3/a/average_absolute_deviation.c3) |
| C++ | [cpp/average_absolute_deviation.cpp](../../../cpp/a/average_absolute_deviation.cpp) |
| Elisa | [elisa/average_absolute_deviation.elisa](../../../elisa/a/average_absolute_deviation.elisa) |
| Nim | [nim/average_absolute_deviation.nim](../../../nim/a/average_absolute_deviation.nim) |
| Odin | [odin/average_absolute_deviation.odin](../../../odin/a/average_absolute_deviation.odin) |
| Rust | [rust/average_absolute_deviation.rs](../../../rust/a/average_absolute_deviation.rs) |
| V | [v/average_absolute_deviation.v](../../../v/a/average_absolute_deviation.v) |
| Zig | [zig/average_absolute_deviation.zig](../../../zig/a/average_absolute_deviation.zig) |
