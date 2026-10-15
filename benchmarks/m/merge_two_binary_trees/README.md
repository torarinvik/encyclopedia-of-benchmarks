# Merge Two Binary Trees

This benchmark ports TheAlgorithms/C's recursive LeetCode 617 algorithm. At each matching position, it adds the node values; when only one tree has a node, it copies that value and keeps its children.

## Contract

- Input is `[left_slot_count, left_slots..., right_slot_count, right_slots...]`. Each tree uses heap indexing: slot `i` has children `2*i+1` and `2*i+2`.
- Each tree has 0 to 255 slots. Values are from -100,000 through 100,000; `-1,000,001` marks a missing slot. A nonempty child cannot follow a missing parent.
- Output is the merged tree's heap-indexed slots through its final nonempty slot. Missing positions keep the sentinel. Each slot is a signed 32-bit little-endian value.
- The return value is the number of nodes in the merged tree. Empty trees are supported.
- Invalid input returns `-1`. Insufficient output capacity returns `-2` before writing output.

The bounded heap-slot representation adapts the pointer-based source to the shared byte-output ABI. It preserves tree positions and does not modify either input.

Run `python3 benchmarks/verify_merge_two_binary_trees.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check the nine ports against an independent tree-merge oracle, including malformed shapes, boundary values, and output-capacity failure.

## Implementations

Portable ports are [`c/m/merge_two_binary_trees.c`](../../../c/m/merge_two_binary_trees.c), [`c3/m/merge_two_binary_trees.c3`](../../../c3/m/merge_two_binary_trees.c3), [`cpp/m/merge_two_binary_trees.cpp`](../../../cpp/m/merge_two_binary_trees.cpp), [`elisa/m/merge_two_binary_trees.elisa`](../../../elisa/m/merge_two_binary_trees.elisa), [`nim/m/merge_two_binary_trees.nim`](../../../nim/m/merge_two_binary_trees.nim), [`odin/m/merge_two_binary_trees.odin`](../../../odin/m/merge_two_binary_trees.odin), [`rust/m/merge_two_binary_trees.rs`](../../../rust/m/merge_two_binary_trees.rs), [`v/m/merge_two_binary_trees.v`](../../../v/m/merge_two_binary_trees.v), and [`zig/m/merge_two_binary_trees.zig`](../../../zig/m/merge_two_binary_trees.zig).

## Upstream reference

- [TheAlgorithms/C LeetCode 617](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/617.c)
