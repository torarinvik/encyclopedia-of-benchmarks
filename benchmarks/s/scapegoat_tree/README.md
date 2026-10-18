# Scapegoat tree operation trace

This benchmark follows the pinned C# `ScapegoatTree<int>` implementation with
its default `Alpha = 0.5`. The adapter supports insert, search, delete, size,
maximum-size, root weight-balance query, and clear operations. Keys are signed
32-bit integers, with at most 32 live distinct keys and at most 64 operations
per trace.

## Source behavior

Insertion rejects duplicate keys and otherwise adds a leaf. For a non-root
insertion, the source rebuilds a scapegoat subtree when the search path length
is greater than `floor(log2(root subtree size))`. It finds the scapegoat while
walking that path upward and rebuilds the scapegoat subtree from its in-order
node list, using the upper middle element as each recursive pivot. Delete
returns false for a missing key, replaces a two-child node with its
in-order predecessor, and rebuilds the whole tree when the remaining size is
less than `0.5 * MaxSize`. Clear resets both `Size` and `MaxSize`.

The output preserves `Size` and `MaxSize` as observable source properties.
When a delete empties the tree, the source does not reset `MaxSize`; a later
insert into that empty tree retains the old maximum until `Clear` or a later
nonempty delete rebuilds it. The source's `IsAlphaWeightBalanced()` method
checks the current root's child subtree sizes only. Tree shape and the
`TreeIsUnbalanced` event are not emitted by this adapter.

## Input and output

The ABI is `i64_array_bytes_output`. Input is
`[operation_count, (opcode, key)...]`, with exactly two words per operation.
Control operations `size`, `maxSize`, `isAlphaWeightBalanced`, and `clear`
require a zero key field.

- Opcode `0` inserts a key; it emits `1` on insertion and `0` for a duplicate.
- Opcode `1` searches for a key and emits `1` on a hit or `0` on a miss.
- Opcode `2` deletes a key and emits `1` on success or `0` when absent.
- Opcode `3` returns `Size`.
- Opcode `4` returns `MaxSize`.
- Opcode `5` returns the source's root weight-balance result as `1` or `0`.
- Opcode `6` clears the tree and emits the adapter tag `-2`.

The output is `[operation_count, operation_results..., final_key_count,
final_keys...]`, with final keys in ascending order. Every word is a little-endian
signed 64-bit integer. The output is at most 784 bytes. Invalid framing,
out-of-range keys, nonzero control fields, unknown opcodes, or a trace that
exceeds 32 live distinct keys returns `-1`. Null output or insufficient
capacity returns `-2` without writes, after input validation.

## Pinned sources and fixtures

The algorithm source is TheAlgorithms/C-Sharp
[`ScapegoatTree.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/ScapegoatTree/ScapegoatTree.cs)
at commit `96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c`. Its node size and alpha
height behavior is in the same commit's
[`Node.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/ScapegoatTree/Node.cs),
and its in-order flatten/rebuild behavior is in
[`Extensions.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/ScapegoatTree/Extensions.cs).
Fixtures and ABI cases are in [workload.json](workload.json); the independent
oracle is [`benchmarks/scapegoat_tree_oracle.py`](../../scapegoat_tree_oracle.py).
