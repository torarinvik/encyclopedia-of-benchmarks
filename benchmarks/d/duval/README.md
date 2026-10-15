# Duval Least Cyclic Shift

Return the zero-based start of a lexicographically least cyclic rotation. The port follows the pinned C++ Duval scan over an ASCII codepoint array. The scan runs in O(n) time with O(1) auxiliary space. An empty input returns 0, matching the source.

## Contract

- Input is an array of 0 to 4,096 signed 64-bit ASCII codepoints in the range 0 through 127.
- The output is the start index chosen by the source scan for a lexicographically least cyclic rotation.
- If several rotations are identical and minimal, the output preserves the representative selected by the source scan rather than normalizing to the smallest index.
- Invalid length or codepoints return -1.
- Input is not modified.

The C++ source applies Duval's scan to find the least cyclic shift. The separately named Rust duval_algorithm candidate performs Lyndon factorization of the input string; that is a different operation and is not mapped to this benchmark.

## Workload

[workload.json](workload.json) includes empty and single-symbol inputs, source examples, periodic strings with tied rotations, varied ASCII sequences, invalid codepoints, and an over-capacity array.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/d/duval.c](../../../c/d/duval.c) |
| C3 | [c3/d/duval.c3](../../../c3/d/duval.c3) |
| C++ | [cpp/d/duval.cpp](../../../cpp/d/duval.cpp) |
| Elisa | [elisa/d/duval.elisa](../../../elisa/d/duval.elisa) |
| Nim | [nim/d/duval.nim](../../../nim/d/duval.nim) |
| Odin | [odin/d/duval.odin](../../../odin/d/duval.odin) |
| Rust | [rust/d/duval.rs](../../../rust/d/duval.rs) |
| V | [v/d/duval.v](../../../v/d/duval.v) |
| Zig | [zig/d/duval.zig](../../../zig/d/duval.zig) |

## Upstream reference

- [TheAlgorithms/C-Plus-Plus duval.cpp](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/duval.cpp)

The source-backed oracle is implemented in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py). Build with the i64_array_scalar ABI family and record with that runner.
