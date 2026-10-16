# Monotonic array

## Contract

Return 1 when the input sequence is entirely nondecreasing or entirely nonincreasing, allowing equal adjacent values; otherwise return 0. Empty and singleton arrays return 1, matching the pinned Python implementation's vacuous all() behavior.

The benchmark accepts up to 256 signed 64-bit values. The ABI returns -1 when the length exceeds 256 or when the input pointer is null with a nonzero length. A null pointer with length zero is valid. Values may use the full signed 64-bit range.

The exported C ABI entry point is:

    int64_t is_monotonic(const int64_t *values, size_t length);

## Workload

workload.json covers empty, singleton, constant, increasing, decreasing, direction-changing, extreme signed values, and maximum-length arrays. Expected results come from the source-derived runtime oracle at ../../monotonic_array_oracle.py. The benchmark uses the i64_array_scalar_call ABI family.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/monotonic_array.c](../../../c/m/monotonic_array.c) |
| C3 | [c3/m/monotonic_array.c3](../../../c3/m/monotonic_array.c3) |
| C++ | [cpp/m/monotonic_array.cpp](../../../cpp/m/monotonic_array.cpp) |
| Elisa | [elisa/m/monotonic_array.elisa](../../../elisa/m/monotonic_array.elisa) |
| Nim | [nim/m/monotonic_array.nim](../../../nim/m/monotonic_array.nim) |
| Odin | [odin/m/monotonic_array.odin](../../../odin/m/monotonic_array.odin) |
| Rust | [rust/m/monotonic_array.rs](../../../rust/m/monotonic_array.rs) |
| V | [v/m/monotonic_array.v](../../../v/m/monotonic_array.v) |
| Zig | [zig/m/monotonic_array.zig](../../../zig/m/monotonic_array.zig) |

## Pinned source

[Python monotonic_array.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/arrays/monotonic_array.py)
