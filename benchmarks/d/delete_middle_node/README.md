# Delete Middle Node

This benchmark ports C LeetCode 2095, which removes the middle node of a singly linked list and returns the possibly changed head. The benchmark uses an indexed link pool so pointer traversal and relinking can be compared without allocator or address-layout differences.

## Contract

- Input is a list of zero to 1,024 signed 32-bit values in list order.
- Invalid lengths or out-of-range values return `-1`. Empty and singleton lists produce an empty list.
- For a list of length `n > 1`, delete node index `floor(n / 2)`. The result is the number of remaining nodes; serialize their values in order as little-endian signed 32-bit integers.
- Insufficient output capacity returns `-2` before writing output.
- Implementations build forward links, advance fast and slow indices using the source's two-traversal midpoint selection, unlink the selected node, and serialize the remaining chain.

The numeric upstream source stem `2095` is cataloged under the alphabetic algorithm name `delete_middle_node`.

Run `python3 benchmarks/verify_delete_middle_node.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine ports against exhaustive short lists, seeded random lists, signed boundaries, maximum length, malformed values, output-capacity failure, and workload records.

## Implementations

Portable ports are [`c/d/delete_middle_node.c`](../../../c/d/delete_middle_node.c), [`c3/d/delete_middle_node.c3`](../../../c3/d/delete_middle_node.c3), [`cpp/d/delete_middle_node.cpp`](../../../cpp/d/delete_middle_node.cpp), [`elisa/d/delete_middle_node.elisa`](../../../elisa/d/delete_middle_node.elisa), [`nim/d/delete_middle_node.nim`](../../../nim/d/delete_middle_node.nim), [`odin/d/delete_middle_node.odin`](../../../odin/d/delete_middle_node.odin), [`rust/d/delete_middle_node.rs`](../../../rust/d/delete_middle_node.rs), [`v/d/delete_middle_node.v`](../../../v/d/delete_middle_node.v), and [`zig/d/delete_middle_node.zig`](../../../zig/d/delete_middle_node.zig). They use generic compiler targets and no architecture-specific instructions.

## Upstream reference

- [TheAlgorithms/C LeetCode 2095](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/2095.c)
