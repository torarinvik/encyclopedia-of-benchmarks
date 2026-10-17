# Table list

This benchmark ports the list-backed table from the pinned
[TheAlgorithms/Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/table_list.lua).
It covers the source's 1-based logical indexing, head/tail operations,
index-based access, bounds checks, and forward/reverse iterators.

## Contract

- ABI: `i64_array_bytes_output`. Input is
  `[operation_count, (opcode, arg1, arg2)*]`, with exactly three signed-i64
  cells per operation. The list starts empty. There are 0..32 operations and
  the list may contain at most 32 values. Payload values are in
  `[-1_000_000, 1_000_000]`; unused arguments must be zero.
- Operation codes are `0 push_head(value)`, `1 push_tail(value)`, `2 pop_head`,
  `3 pop_tail`, `4 get_head`, `5 get_tail`, `6 get(index)`, `7 set(index,value)`,
  `8 in_bounds(index)`, `9 len`, `10 consume ipairs()`, and
  `11 consume rpairs()`. Indices are 1-based, as in the source. `in_bounds`
  accepts `-1..33` and returns 1 or 0. `get` and `set` require an in-bounds
  index; the source asserts for an out-of-bounds access. Empty pops and empty
  head/tail reads return nil.
- Each operation emits a little-endian signed-i64 record
  `[opcode, return_count, values...]`. Pushes and `set` return no values.
  Empty pops and head/tail reads emit a zero count; nonempty pops and reads
  emit one value. `get`, `len`, and `in_bounds` emit one value. Iterator records
  use the yielded-pair count followed by `(logical_index, value)` pairs in the
  source's iteration order. A final snapshot record `[12, list_length, values...]`
  records the remaining list from head to tail.
- Invalid framing, operation codes, unused arguments, payloads, indices, or
  list sizes return `-1`. Input validation takes precedence over output-buffer
  errors. A null output pointer or insufficient capacity returns `-2` without
  writing. Success returns the number of output bytes. The largest valid input
  contains 97 values; 98 values are parseable for malformed-framing checks.
  A safe tight bound for output is 4,752 bytes (594 signed-i64 fields), attained
  by 16 pushes followed by 16 full iterator operations at length 16.

The independent oracle is
[`benchmarks/table_list_oracle.py`](../../table_list_oracle.py), and
[`workload.json`](workload.json) covers endpoint access and mutation, indexed
operations, both iterator orders, nil returns, boundary sizes, and malformed
or output-buffer cases.

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/t/table_list.c`](../../../c/t/table_list.c) |
| C3 | [`c3/t/table_list.c3`](../../../c3/t/table_list.c3) |
| C++ | [`cpp/t/table_list.cpp`](../../../cpp/t/table_list.cpp) |
| Elisa | [`elisa/t/table_list.elisa`](../../../elisa/t/table_list.elisa) |
| Nim | [`nim/t/table_list.nim`](../../../nim/t/table_list.nim) |
| Odin | [`odin/t/table_list.odin`](../../../odin/t/table_list.odin) |
| Rust | [`rust/t/table_list.rs`](../../../rust/t/table_list.rs) |
| V | [`v/t/table_list.v`](../../../v/t/table_list.v) |
| Zig | [`zig/t/table_list.zig`](../../../zig/t/table_list.zig) |
