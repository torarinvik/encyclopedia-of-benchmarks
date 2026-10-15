# Average absolute deviation, rounded

Compute the mean absolute deviation and round the binary64 result to two decimal places using ties to even. This captures the pinned Julia implementation's rounded output for the bounded integer input domain.

## Contract

- Input is an array of 1 to 256 signed 32-bit integers, passed through the signed 64-bit array ABI.
- Compute the arithmetic mean, then the mean absolute deviation, preserving input order, and round the result to two decimal places with ties to even.
- Empty arrays, arrays longer than 256, and values outside signed 32-bit range return -1e300. The Julia source's empty arithmetic is non-finite, which this benchmark runner cannot compare.
- This bounded integer domain keeps all sums finite. The algorithm uses O(n) time and O(1) auxiliary space.

## Source and related algorithms

The pinned [Julia implementation](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/average_absolute_deviation.jl) accepts Number vectors and rounds to two decimal places. The pinned [Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/average_absolute_deviation.py) returns the unrounded value; see [average_absolute_deviation](../average_absolute_deviation/README.md) for that separate contract.

## Workload

[workload.json](workload.json) covers the Julia example adapted to integer inputs, a fractional result that rounds, and boundary and invalid cases. All nine ports use the i64_array_float64 ABI family.

| Language | Source |
| --- | --- |
| C | [c/average_absolute_deviation_rounded.c](../../../c/a/average_absolute_deviation_rounded.c) |
| C3 | [c3/average_absolute_deviation_rounded.c3](../../../c3/a/average_absolute_deviation_rounded.c3) |
| C++ | [cpp/average_absolute_deviation_rounded.cpp](../../../cpp/a/average_absolute_deviation_rounded.cpp) |
| Elisa | [elisa/average_absolute_deviation_rounded.elisa](../../../elisa/a/average_absolute_deviation_rounded.elisa) |
| Nim | [nim/average_absolute_deviation_rounded.nim](../../../nim/a/average_absolute_deviation_rounded.nim) |
| Odin | [odin/average_absolute_deviation_rounded.odin](../../../odin/a/average_absolute_deviation_rounded.odin) |
| Rust | [rust/average_absolute_deviation_rounded.rs](../../../rust/a/average_absolute_deviation_rounded.rs) |
| V | [v/average_absolute_deviation_rounded.v](../../../v/a/average_absolute_deviation_rounded.v) |
| Zig | [zig/average_absolute_deviation_rounded.zig](../../../zig/a/average_absolute_deviation_rounded.zig) |
