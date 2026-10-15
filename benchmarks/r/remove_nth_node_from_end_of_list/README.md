# Remove Nth Node From End of List

This benchmark removes the one-based `position_from_end` node from a singly linked list and returns the remaining values in list order. It combines the C LeetCode 19 source with TheAlgorithms/Python's `remove_nth_from_end` method; both implement the same operation. The C solution counts nodes and walks to the predecessor. The Python source validates the position, advances one pointer by that distance, then advances two pointers together.

## Contract

- Input is `[position_from_end, value_0, ..., value_(n-1)]`, with 1 to 1,024 signed 32-bit list values.
- Position 1 removes the tail; position equal to list length removes the head. Invalid lengths, positions, or values return `-1`.
- The output is the remaining list serialized as little-endian signed 32-bit values. The return value is the output element count. Insufficient output capacity returns `-2`.
- Implementations use a bounded index-based singly linked chain, count its nodes, unlink the selected node, and serialize the chain. This keeps linked-list traversal and removal semantics while avoiding platform-specific pointer layouts and allocator behavior.

The numeric LeetCode filename `19.c` is cataloged as an alias of this alphabetically named algorithm. The C and Python sources were inspected at their pinned revisions below.

Run `python3 benchmarks/verify_remove_nth_node_from_end_of_list.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short lists, seeded randomized inputs, boundary values, invalid cases, output-capacity failure, and workload records.

## Implementations

The portable ports are [`c/r/remove_nth_node_from_end_of_list.c`](../../../c/r/remove_nth_node_from_end_of_list.c), [`c3/r/remove_nth_node_from_end_of_list.c3`](../../../c3/r/remove_nth_node_from_end_of_list.c3), [`cpp/r/remove_nth_node_from_end_of_list.cpp`](../../../cpp/r/remove_nth_node_from_end_of_list.cpp), [`elisa/r/remove_nth_node_from_end_of_list.elisa`](../../../elisa/r/remove_nth_node_from_end_of_list.elisa), [`nim/r/remove_nth_node_from_end_of_list.nim`](../../../nim/r/remove_nth_node_from_end_of_list.nim), [`odin/r/remove_nth_node_from_end_of_list.odin`](../../../odin/r/remove_nth_node_from_end_of_list.odin), [`rust/r/remove_nth_node_from_end_of_list.rs`](../../../rust/r/remove_nth_node_from_end_of_list.rs), [`v/r/remove_nth_node_from_end_of_list.v`](../../../v/r/remove_nth_node_from_end_of_list.v), and [`zig/r/remove_nth_node_from_end_of_list.zig`](../../../zig/r/remove_nth_node_from_end_of_list.zig). They use generic targets without architecture-specific instructions.

## Upstream references

- [C LeetCode 19](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/19.c)
- [Python `remove_nth_node_from_end_of_list.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/linked_list/remove_nth_node_from_end_of_list.py)
