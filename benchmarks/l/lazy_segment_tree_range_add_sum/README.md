# Lazy Segment Tree Range Add and Sum

This benchmark measures the Rust source's lazy segment tree configured with addition as its merge/update operation. It applies a delta to a range and returns sums over ranges. The Python source is a separate range-assignment/maximum benchmark; the Java source is excluded because its propagation applies lazy updates twice.

## Contract

- Input is a signed 64-bit array packed as [n, initial_values..., q, (opcode, left, right, delta)*].
- The array length n is 1 through 256; operation count q is 0 through 512. Initial values and update deltas are in [-1,000,000, 1,000,000].
- Both operations use nonempty, zero-based half-open ranges with 0 <= left < right <= n. Opcode 0 adds delta to each value in the range. Opcode 1 queries the range sum and requires delta to be zero.
- Invalid lengths, opcodes, ranges, values, or nonzero query deltas return -1.
- For each query, add the returned range sum plus 131,328,000,001 to the result. The result is zero if there are no queries. With the bounded inputs, every query term is positive, the result fits signed 64-bit, and valid input cannot return the invalid sentinel -1.
- The maximum packed input has 2 + 256 + 4 * 512 = 2,306 signed 64-bit values.

## Workload and implementation

The workload covers single-element and partial ranges, overlapping positive and negative additions, repeated queries, no-query traces, value limits, and malformed input. All nine ports use the i64-array scalar ABI.

Each port stores range sums and pending additions in a complete binary tree. Padded leaves are zero and valid ranges never include them. Range additions update a covered node in one step; queries push pending additions before descending.

## Upstream source

[Rust lazy_segment_tree.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/lazy_segment_tree.rs)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/lazy_segment_tree_range_add_sum.c](../../../c/l/lazy_segment_tree_range_add_sum.c) |
| C3 | [c3/l/lazy_segment_tree_range_add_sum.c3](../../../c3/l/lazy_segment_tree_range_add_sum.c3) |
| C++ | [cpp/l/lazy_segment_tree_range_add_sum.cpp](../../../cpp/l/lazy_segment_tree_range_add_sum.cpp) |
| Elisa | [elisa/l/lazy_segment_tree_range_add_sum.elisa](../../../elisa/l/lazy_segment_tree_range_add_sum.elisa) |
| Nim | [nim/l/lazy_segment_tree_range_add_sum.nim](../../../nim/l/lazy_segment_tree_range_add_sum.nim) |
| Odin | [odin/l/lazy_segment_tree_range_add_sum.odin](../../../odin/l/lazy_segment_tree_range_add_sum.odin) |
| Rust | [rust/l/lazy_segment_tree_range_add_sum.rs](../../../rust/l/lazy_segment_tree_range_add_sum.rs) |
| V | [v/l/lazy_segment_tree_range_add_sum.v](../../../v/l/lazy_segment_tree_range_add_sum.v) |
| Zig | [zig/l/lazy_segment_tree_range_add_sum.zig](../../../zig/l/lazy_segment_tree_range_add_sum.zig) |
