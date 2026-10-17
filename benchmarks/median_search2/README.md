# Middle node of a singly linked list

This benchmark follows the `middleNode` operation in two pinned C++ copies. The
algorithm advances a slow pointer by one node and a fast pointer by two, then
returns the selected node rather than its value. Empty input returns no node;
even-length lists select the second middle node.

## Contract

- ABI: `i64_array_bytes_output`.
- Input is `[n, value_0, ..., value_(n-1)]`, where `n` is 0 through 128 and the
  input length is exactly `n + 1` signed-i64 words. Each value must fit signed
  32-bit range. Values may repeat and need not be sorted. The wrapper builds a
  finite, acyclic singly linked chain in the given order.
- For an empty list, output is `[0, -1]`. For a nonempty list, output is
  `[1, floor(n / 2)]`, identifying the selected node by its zero-based
  position. Thus an even-length list selects its second middle, and duplicate
  values do not hide which node was selected.
- Output is two little-endian signed-i32 words and is always 8 bytes for valid
  input. A null input pointer or malformed input returns `-1` before output
  checks. A null output pointer or capacity below 8 bytes returns `-2` without
  writing, including for an empty list.
- Workspace is 8 bytes. The independent oracle is
  [`median_search2_oracle.py`](../median_search2_oracle.py).

The workload covers empty, singleton, odd and even lengths, duplicate node
values, negative and boundary values, maximum size, malformed framing, and
null, zero, short, exact, and maximum output capacities.

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `median_search2.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/search/median_search2.cpp)
  at commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.
- [TheAlgorithms/C-Plus-Plus-1 `median_search2.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/search/median_search2.cpp)
  at commit `0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680`.

## Language ports

| Language | Port |
| --- | --- |
| C | [c/m/median_search2.c](../../c/m/median_search2.c) |
| C3 | [c3/m/median_search2.c3](../../c3/m/median_search2.c3) |
| C++ | [cpp/m/median_search2.cpp](../../cpp/m/median_search2.cpp) |
| Elisa | [elisa/m/median_search2.elisa](../../elisa/m/median_search2.elisa) |
| Nim | [nim/m/median_search2.nim](../../nim/m/median_search2.nim) |
| Odin | [odin/m/median_search2.odin](../../odin/m/median_search2.odin) |
| Rust | [rust/m/median_search2.rs](../../rust/m/median_search2.rs) |
| V | [v/m/median_search2.v](../../v/m/median_search2.v) |
| Zig | [zig/m/median_search2.zig](../../zig/m/median_search2.zig) |
