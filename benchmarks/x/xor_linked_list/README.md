# XOR linked list

The pinned Python source appends each value at the tail of an XOR-linked list, then traverses it from the head. Python simulates addresses with an object-ID-to-node map. These ports use stable synthetic node IDs 1 through n and an ID-to-value map; each node stores previous-ID XOR next-ID. The output is the source traversal order encoded as signed 64-bit little-endian values.

## Contract

The i64_array_bytes_output ABI receives [n, value_0, ..., value_(n-1)]. The count is 0 through 64, the packed input length is exactly 1+n, and values are signed 32-bit integers. The output is n as an i64 little-endian word followed by each traversed value widened to i64 and encoded little-endian. Maximum output size is 520 bytes. Invalid input returns -1; a null output pointer or insufficient capacity returns -2 without writing output.

The pinned source is TheAlgorithms/Python, commit e1a2a8b016001309a73d5fec4818c35cca139795, path data_structures/linked_list/xor_linked_list.py. See the [pinned source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/xor_linked_list.py), [workload](workload.json), and [oracle](../../xor_linked_list_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/x/xor_linked_list.c |
| C3 | ../../../c3/x/xor_linked_list.c3 |
| C++ | ../../../cpp/x/xor_linked_list.cpp |
| Elisa | ../../../elisa/x/xor_linked_list.elisa |
| Nim | ../../../nim/x/xor_linked_list.nim |
| Odin | ../../../odin/x/xor_linked_list.odin |
| Rust | ../../../rust/x/xor_linked_list.rs |
| V | ../../../v/x/xor_linked_list.v |
| Zig | ../../../zig/x/xor_linked_list.zig |

Build and record with the shared i64_array_bytes_output ABI after serialized integration is complete:

python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm xor_linked_list --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm xor_linked_list
