# Sqrt Tree

This benchmark builds a recursive sqrt tree for a static integer array and answers inclusive range-minimum queries. Each node stores per-block prefix and suffix minima and a table of minima spanning whole blocks. A query inside one block descends into that child; a query crossing blocks combines the left suffix, any complete middle blocks, and the right prefix.

## Contract

- Input is a packed signed 64-bit array: `[item_count, query_count, value_0, ..., value_(n-1), left_0, right_0, ...]`.
- `item_count` is from 1 through 256, `query_count` is from 0 through 256, values are from -1,000,000,000 through 1,000,000,000, and each query is an inclusive zero-based range `0 <= left <= right < item_count`.
- The structure is built once, then each query emits its minimum as one signed 64-bit little-endian value. The return value is the number of output bytes (`8 * query_count`).
- Invalid input returns `-1`. A null output for nonempty results or a capacity below `8 * query_count` returns `-2`; errors write no output. A zero-query call returns zero and may use a null output pointer.
- The benchmark uses the recursive sqrt-tree construction from the article's description: block size is `ceil(sqrt(segment_length))`, with the final block allowed to be shorter. It has `O(n log log n)` preprocessing and storage and `O(log log n)` worst-case query time; this bounded profile does not implement the article's later power-of-two optimization for `O(1)` queries or its update variants.

[`workload.json`](workload.json) contains hand-checkable cases for nested-block queries, cross-block queries, single-element ranges, empty output, malformed input, null output, and short output capacity. The independent oracle answers each query by scanning its range.

## Attribution and license

Adapted from the recursive construction in [cp-algorithms' Sqrt Tree article](https://cp-algorithms.com/data_structures/sqrt-tree.html), credited there to cp-algorithms contributors including alex65536, algmyr, adamant-pwn, jakobkogler, and wikku. The article states that its text is available under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). This package is an adaptation, records the bounded choices and implementation changes above, and is distributed under the same license; see [`LICENSE.txt`](LICENSE.txt).

## Implementations

The nine ports use the `i64_array_bytes_output` ABI. Their sources are linked below.

| Language | Source |
| --- | --- |
| C | [`c/s/sqrt_tree.c`](../../../c/s/sqrt_tree.c) |
| C3 | [`c3/s/sqrt_tree.c3`](../../../c3/s/sqrt_tree.c3) |
| C++ | [`cpp/s/sqrt_tree.cpp`](../../../cpp/s/sqrt_tree.cpp) |
| Elisa | [`elisa/s/sqrt_tree.elisa`](../../../elisa/s/sqrt_tree.elisa) |
| Nim | [`nim/s/sqrt_tree.nim`](../../../nim/s/sqrt_tree.nim) |
| Odin | [`odin/s/sqrt_tree.odin`](../../../odin/s/sqrt_tree.odin) |
| Rust | [`rust/s/sqrt_tree.rs`](../../../rust/s/sqrt_tree.rs) |
| V | [`v/s/sqrt_tree.v`](../../../v/s/sqrt_tree.v) |
| Zig | [`zig/s/sqrt_tree.zig`](../../../zig/s/sqrt_tree.zig) |
