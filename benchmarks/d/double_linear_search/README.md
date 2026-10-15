# Double linear search

Search a signed integer sequence from both ends at once. The implementation checks the current left endpoint first, then the current right endpoint, and moves both inward after a miss.

## Contract

- The signed 64-bit input array is `[target, item_count, item_0, ..., item_(n-1)]`.
- `item_count` is from 0 through 100,000 and the input length must equal `item_count + 2`.
- The target and every item must be within the exact integer range `[-9,007,199,254,740,991, 9,007,199,254,740,991]`.
- Return the zero-based index selected by the source probe order: check the left endpoint first, then the right endpoint, then move inward. Return `-1` when no item matches or the packed input is invalid.
- Duplicate matches follow that probe order. For example, `[0, 5, 2, 5]` searched for `5` returns index `3` because the right endpoint is checked before the interior match.

## Workload

[`workload.json`](workload.json) covers empty and singleton inputs, hits at both ends and the middle, misses, duplicate values with endpoint priority, malformed packed lengths, and out-of-range values.

## Pinned sources

- [Python `double_linear_search.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/searches/double_linear_search.py)
- [Ruby `double_linear_search.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/searches/double_linear_search.rb)

The shared `i64_array_scalar` runner checks the bounded exact-integer input and left-before-right probe order, including duplicate matches.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/d/double_linear_search.c`](../../../c/d/double_linear_search.c) |
| C3 | [`c3/d/double_linear_search.c3`](../../../c3/d/double_linear_search.c3) |
| C++ | [`cpp/d/double_linear_search.cpp`](../../../cpp/d/double_linear_search.cpp) |
| Elisa | [`elisa/d/double_linear_search.elisa`](../../../elisa/d/double_linear_search.elisa) |
| Nim | [`nim/d/double_linear_search.nim`](../../../nim/d/double_linear_search.nim) |
| Odin | [`odin/d/double_linear_search.odin`](../../../odin/d/double_linear_search.odin) |
| Rust | [`rust/d/double_linear_search.rs`](../../../rust/d/double_linear_search.rs) |
| V | [`v/d/double_linear_search.v`](../../../v/d/double_linear_search.v) |
| Zig | [`zig/d/double_linear_search.zig`](../../../zig/d/double_linear_search.zig) |
