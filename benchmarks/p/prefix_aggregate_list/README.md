# Prefix aggregate list

This package ports the pinned Lua `prefix_aggregate_list` class with addition as its binary operation and subtraction as its inverse. It stores prefix sums, supports appending and removing the final value, and answers inclusive range-sum queries from two prefix aggregates.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[initial_count, initial_values..., operation_count, operation_records...]`. `initial_count` is 1..64, `operation_count` is 0..64, and each initial or appended value is in [-1,000,000, 1,000,000]. The largest live list has 128 values; the maximum valid input length is 258 signed 64-bit integers.
- Operation records are append `[0, value]`, remove-last `[1]`, and inclusive range query `[2, from, to]`. Query indices are 1-based, and require `1 <= from <= to <= current_length`.
- Removing the only live value is outside the benchmark domain. This keeps the list nonempty for any later append; in the Lua source, append after removal of the last value would call the operation with a `nil` prefix.
- Every field must be present, records must consume the input exactly, and all values and indices must satisfy their bounds. Invalid input returns `-1` before output storage is checked.
- Each query emits its signed 64-bit sum in little-endian byte order. The function returns eight times the number of queries, up to 512 bytes. A valid call with no queries returns `0` when given a nonnull output pointer and zero capacity. Null output or insufficient capacity returns `-2` without writes, including when there are no queries.

The Lua source accepts an operation and inverse as callbacks. Fixing them to addition and subtraction makes the result deterministic and preserves exact integer behavior: with at most 128 live values, every prefix sum has magnitude at most 128,000,000, which is exactly representable by Lua's numeric type.

## Workload and source

[`workload.json`](workload.json) covers construction, append/remove updates, inclusive ranges, signed values, the maximum input and output sizes, malformed records, and output capacity errors. The independent [oracle](../../prefix_aggregate_list_oracle.py) returns query sums as little-endian signed-i64 bytes.

Pinned source: [TheAlgorithms/Lua `prefix_aggregate_list.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/prefix_aggregate_list.lua), including `pal.new`, `pal:append`, `pal:remove`, and `pal:aggregate`.

| Language | Port |
|---|---|
| C | [`c/p/prefix_aggregate_list.c`](../../../c/prefix_aggregate_list.c) |
| C3 | [`c3/p/prefix_aggregate_list.c3`](../../../c3/p/prefix_aggregate_list.c3) |
| C++ | [`cpp/p/prefix_aggregate_list.cpp`](../../../cpp/prefix_aggregate_list.cpp) |
| Elisa | [`elisa/p/prefix_aggregate_list.elisa`](../../../elisa/p/prefix_aggregate_list.elisa) |
| Nim | [`nim/p/prefix_aggregate_list.nim`](../../../nim/prefix_aggregate_list.nim) |
| Odin | [`odin/p/prefix_aggregate_list.odin`](../../../odin/prefix_aggregate_list.odin) |
| Rust | [`rust/p/prefix_aggregate_list.rs`](../../../rust/prefix_aggregate_list.rs) |
| V | [`v/p/prefix_aggregate_list.v`](../../../v/prefix_aggregate_list.v) |
| Zig | [`zig/p/prefix_aggregate_list.zig`](../../../zig/prefix_aggregate_list.zig) |
