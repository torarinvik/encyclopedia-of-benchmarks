# Arrays intersection

This benchmark follows the pinned Ruby `arrays_intersection` routine. It counts each occurrence across three arrays and returns keys whose combined count is exactly three. Ruby's `Hash` preserves first insertion order, so the output follows first-seen order across the first, second, and third input arrays.

The source's count test is observable when inputs contain duplicates: a key may be returned after three occurrences in one or two arrays, while four or more occurrences are excluded. The benchmark preserves that behavior instead of imposing a sorted-array or one-occurrence-per-array rule. This is distinct from [`sorted_arrays_intersection`](../../s/sorted_arrays_intersection/README.md), which requires strictly increasing arrays and emits ascending results.

## Contract

- Pack input as `[n1, array1..., n2, array2..., n3, array3...]`. Each length is 0 through 64, and the packed input has exactly `3 + n1 + n2 + n3` signed 64-bit values.
- Array values must fit signed 32-bit integers. Arrays may be unsorted and may contain duplicates.
- Count every value occurrence across all three arrays. Emit each distinct value whose aggregate count is exactly 3, in first-occurrence order over the concatenated arrays.
- Output values are little-endian signed 32-bit integers. The return value is the number of values written; an empty result returns 0 and writes zero bytes.
- Malformed input returns `-1`; insufficient output capacity returns `-2`. At most 64 values (256 bytes) can be emitted.

The ports use a fixed open-addressing table and a separate first-seen slot list to reproduce the source's visible Hash ordering. They use O(1) bounded storage and scan at most 192 input values.

[`workload.json`](workload.json) covers the pinned examples, unsorted input order, duplicate-count behavior, signed 32-bit boundaries, and malformed packed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/arrays_intersection.c`](../../../c/a/arrays_intersection.c) |
| C3 | [`c3/a/arrays_intersection.c3`](../../../c3/a/arrays_intersection.c3) |
| C++ | [`cpp/a/arrays_intersection.cpp`](../../../cpp/a/arrays_intersection.cpp) |
| Elisa | [`elisa/a/arrays_intersection.elisa`](../../../elisa/a/arrays_intersection.elisa) |
| Nim | [`nim/a/arrays_intersection.nim`](../../../nim/a/arrays_intersection.nim) |
| Odin | [`odin/a/arrays_intersection.odin`](../../../odin/a/arrays_intersection.odin) |
| Rust | [`rust/a/arrays_intersection.rs`](../../../rust/a/arrays_intersection.rs) |
| V | [`v/a/arrays_intersection.v`](../../../v/a/arrays_intersection.v) |
| Zig | [`zig/a/arrays_intersection.zig`](../../../zig/a/arrays_intersection.zig) |

## TheAlgorithms reference

- [Ruby `arrays_intersection.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/hash_table/arrays_intersection.rb)
