# Swap Nodes

This package benchmarks the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/swap_nodes.py). Build a linked list in input order, find the first node matching each requested value, and swap those nodes’ data fields. Equal or missing requested values leave the list unchanged. Return the final values as a count followed by signed 64-bit little-endian values.

The `i64_array_bytes_output` ABI uses the packed input layout `[n,values[0..n],value_a,value_b]`. The workload records the exact input bounds, output encoding, invalid-input result `-1`, insufficient-capacity result `-2`, and bounded output workspace.

Time is O(n); auxiliary space is O(n) for the linked-list representation.

See [`workload.json`](workload.json) for boundary and invalid-input cases. The independent oracle is [`swap_nodes_oracle.py`](../../swap_nodes_oracle.py).

## Language ports

- C: [`c/s/swap_nodes.c`](../../../c/s/swap_nodes.c)
- C3: [`c3/s/swap_nodes.c3`](../../../c3/s/swap_nodes.c3)
- C++: [`cpp/s/swap_nodes.cpp`](../../../cpp/s/swap_nodes.cpp)
- Elisa: [`elisa/s/swap_nodes.elisa`](../../../elisa/s/swap_nodes.elisa)
- Nim: [`nim/s/swap_nodes.nim`](../../../nim/s/swap_nodes.nim)
- Odin: [`odin/s/swap_nodes.odin`](../../../odin/s/swap_nodes.odin)
- Rust: [`rust/s/swap_nodes.rs`](../../../rust/s/swap_nodes.rs)
- V: [`v/s/swap_nodes.v`](../../../v/s/swap_nodes.v)
- Zig: [`zig/s/swap_nodes.zig`](../../../zig/s/swap_nodes.zig)
