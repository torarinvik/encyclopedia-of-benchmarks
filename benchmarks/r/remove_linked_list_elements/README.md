# Remove Linked List Elements

This benchmark ports C LeetCode 203, which recursively removes every node whose value equals a target. The benchmark represents the linked list with an indexed node pool so the recursive link rewrites can be compared across languages without allocator or pointer-layout differences.

## Contract

- Input is `[target, node0, node1, ...]`: one signed 32-bit target followed by zero to 1,024 signed 32-bit node values.
- Invalid lengths or out-of-range values return `-1`.
- The result is the number of surviving nodes. Their values are serialized in list order as little-endian signed 32-bit integers.
- Insufficient output capacity returns `-2` before writing any output bytes.
- Each implementation builds a forward link chain, recursively returns the new head of each suffix, and rewrites links for retained nodes.

The numeric upstream filename `203.c` is cataloged under the alphabetic algorithm name `remove_linked_list_elements`. The input list is immutable from the caller's perspective; the link pool is local to each call.

Run `python3 benchmarks/verify_remove_linked_list_elements.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short lists, seeded random lists, signed 32-bit boundaries, maximum recursion depth, malformed values, output-capacity failure, and workload records.

## Implementations

The portable ports are [`c/r/remove_linked_list_elements.c`](../../../c/r/remove_linked_list_elements.c), [`c3/r/remove_linked_list_elements.c3`](../../../c3/r/remove_linked_list_elements.c3), [`cpp/r/remove_linked_list_elements.cpp`](../../../cpp/r/remove_linked_list_elements.cpp), [`elisa/r/remove_linked_list_elements.elisa`](../../../elisa/r/remove_linked_list_elements.elisa), [`nim/r/remove_linked_list_elements.nim`](../../../nim/r/remove_linked_list_elements.nim), [`odin/r/remove_linked_list_elements.odin`](../../../odin/r/remove_linked_list_elements.odin), [`rust/r/remove_linked_list_elements.rs`](../../../rust/r/remove_linked_list_elements.rs), [`v/r/remove_linked_list_elements.v`](../../../v/r/remove_linked_list_elements.v), and [`zig/r/remove_linked_list_elements.zig`](../../../zig/r/remove_linked_list_elements.zig). The implementations use generic compiler targets and no architecture-specific instructions.

## Upstream reference

- [TheAlgorithms/C LeetCode 203](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/203.c)
