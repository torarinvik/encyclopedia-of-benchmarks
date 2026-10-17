# Magic sequence

Enumerate the source's self-describing integer vectors with bounded backtracking. A length-`n` vector contains values `0..n-1`; it is magic when each value `i` occurs exactly `vector[i]` times. The search visits vectors lexicographically and prunes any partial prefix whose sum exceeds `n`.

## Contract

- The `i64_array_scalar` input is exactly `[n]`, where `n` is from 0 through 11. A null pointer, any other input length, or an out-of-range value returns `-1`.
- The result is the low 63 bits of FNV-1a-64 over this byte stream: `n` as one unsigned byte; the number of retained solutions as a four-byte unsigned little-endian integer; then every solution row in source lexicographic order, with each row value encoded as one unsigned byte. The fixed row length `n` makes row boundaries implicit.
- `n=0` retains one empty solution, matching the source recursion's base case. Its hash includes the solution count `1` and no row bytes. `n=1..3` have no solutions.
- The ports keep the source's prefix-sum pruning and lexicographic traversal. They carry prefix sums and value frequencies incrementally; each full vector is retained exactly when every frequency matches the vector entry.

## Workload and source

[`workload.json`](workload.json) includes every valid `n` from 0 through 11, the solution count for each size, malformed lengths, signed 64-bit bounds, and the null-input case. [`benchmarks/magic_sequence_oracle.py`](../../magic_sequence_oracle.py) independently enumerates bounded weak compositions of `n`, checks their self-description, and hashes the lexicographically ordered solutions.

The benchmark is based on TheAlgorithms/C-Plus-Plus [`magic_sequence.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/backtracking/magic_sequence.cpp). Its solver assigns each position values `0..n-1`, searches sizes 2 through 11 in its demonstration `main`, prunes prefixes whose sum exceeds `n`, and stores valid vectors in lexicographic traversal order. The [second C++ snapshot](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/backtracking/magic_sequence.cpp) is the same algorithm family. This benchmark exposes the bounded search through a scalar call and includes `n=0` and `n=1` as boundary cases.

| Language | Port |
| --- | --- |
| C | [c/m/magic_sequence.c](../../../c/m/magic_sequence.c) |
| C3 | [c3/m/magic_sequence.c3](../../../c3/m/magic_sequence.c3) |
| C++ | [cpp/m/magic_sequence.cpp](../../../cpp/m/magic_sequence.cpp) |
| Elisa | [elisa/m/magic_sequence.elisa](../../../elisa/m/magic_sequence.elisa) |
| Nim | [nim/m/magic_sequence.nim](../../../nim/m/magic_sequence.nim) |
| Odin | [odin/m/magic_sequence.odin](../../../odin/m/magic_sequence.odin) |
| Rust | [rust/m/magic_sequence.rs](../../../rust/m/magic_sequence.rs) |
| V | [v/m/magic_sequence.v](../../../v/m/magic_sequence.v) |
| Zig | [zig/m/magic_sequence.zig](../../../zig/m/magic_sequence.zig) |

Build with the shared `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.
