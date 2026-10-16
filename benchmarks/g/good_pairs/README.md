# Good pairs

Count index pairs `(i, j)` where `i < j` and the two array values are equal. This preserves the pinned Ruby implementation's nested-loop brute-force algorithm.

## Contract

- Input is a signed 64-bit integer array `[n, values...]`, with `n` from 0 through 256 and exactly `n + 1` packed values. Each value is in `[-1,000,000, 1,000,000]`.
- Return the number of matching index pairs as a signed 64-bit integer. Empty and singleton arrays return zero.
- Malformed input returns `-1`. The bound limits the result to `256*255/2 = 32,640`.
- The algorithm takes `O(n²)` time and `O(1)` auxiliary space, matching the source's two nested scans.

## Source and workload

Pinned source: [TheAlgorithms/Ruby `good_pairs.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/arrays/good_pairs.rb). The source compares each value against later positions and increments the count for equal values. The separate [`data_structures/hash_table/good_pairs.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/hash_table/good_pairs.rb) uses a frequency map and is not covered by this brute-force package.

[`workload.json`](workload.json) covers the source examples, all-equal and distinct inputs, negative and boundary values, empty/singleton inputs, and malformed packing. All nine ports use the `i64_array_scalar` ABI.

| Language | Source |
| --- | --- |
| C | [c/g/good_pairs.c](../../../c/g/good_pairs.c) |
| C3 | [c3/g/good_pairs.c3](../../../c3/g/good_pairs.c3) |
| C++ | [cpp/g/good_pairs.cpp](../../../cpp/g/good_pairs.cpp) |
| Elisa | [elisa/g/good_pairs.elisa](../../../elisa/g/good_pairs.elisa) |
| Nim | [nim/g/good_pairs.nim](../../../nim/g/good_pairs.nim) |
| Odin | [odin/g/good_pairs.odin](../../../odin/g/good_pairs.odin) |
| Rust | [rust/g/good_pairs.rs](../../../rust/g/good_pairs.rs) |
| V | [v/g/good_pairs.v](../../../v/g/good_pairs.v) |
| Zig | [zig/g/good_pairs.zig](../../../zig/g/good_pairs.zig) |

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.
