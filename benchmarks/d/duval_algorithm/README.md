# Duval Lyndon Factorization

Factor an ASCII sequence into its standard nonincreasing sequence of Lyndon words using Duval's linear-time algorithm. The contract preserves the Rust source's factor boundaries while encoding each factor as a length word to avoid allocating or returning concatenated text.

## Contract

- Input is 0 to 4,096 signed 64-bit ASCII codepoints in the range 0 through 127.
- Output is one unsigned 32-bit little-endian factor length for each Lyndon factor, in source order. Applying the lengths consecutively to the original input reconstructs the vector of factor strings.
- The function returns the factor count. Empty input returns zero factors and no bytes.
- Invalid length or codepoints return -1. Insufficient output capacity returns -2 before output is written.
- The algorithm uses O(n) time; the output buffer holds O(n) factor lengths.

The pinned Rust source returns a vector of factor strings. This benchmark narrows input to ASCII and changes only the output representation. The separate duval candidate from C++ finds a least cyclic rotation index and is not the same operation.

## Workload

[workload.json](workload.json) covers the pinned Rust examples, empty/single-character input, repeated symbols, monotone and mixed sequences, invalid codepoints, and short output capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/d/duval_algorithm.c](../../../c/d/duval_algorithm.c) |
| C3 | [c3/d/duval_algorithm.c3](../../../c3/d/duval_algorithm.c3) |
| C++ | [cpp/d/duval_algorithm.cpp](../../../cpp/d/duval_algorithm.cpp) |
| Elisa | [elisa/d/duval_algorithm.elisa](../../../elisa/d/duval_algorithm.elisa) |
| Nim | [nim/d/duval_algorithm.nim](../../../nim/d/duval_algorithm.nim) |
| Odin | [odin/d/duval_algorithm.odin](../../../odin/d/duval_algorithm.odin) |
| Rust | [rust/d/duval_algorithm.rs](../../../rust/d/duval_algorithm.rs) |
| V | [v/d/duval_algorithm.v](../../../v/d/duval_algorithm.v) |
| Zig | [zig/d/duval_algorithm.zig](../../../zig/d/duval_algorithm.zig) |

## Upstream reference

- [TheAlgorithms/Rust duval_algorithm.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/duval_algorithm.rs)

The shared byte-output runner validates results with the pinned Duval factorization recurrence. Build with the i64_array_bytes_output ABI family and record with benchmarks/run_i64_array_bytes_output.py.
