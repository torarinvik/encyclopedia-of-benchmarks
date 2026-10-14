# Level-order traversal

This benchmark performs queue-based breadth-first traversal of an indexed binary tree. It preserves the upstream `traverse` method's left-to-right child order and grouping by depth. The Java source also provides a recursive `printGivenLevel` helper; this contract follows its queue-based grouped traversal.

## Contract

- The input node table contains up to 4,096 `[value, left_child_index, right_child_index]` signed 64-bit triplets. Child index `-1` means absent; all other child indices refer to a node in the table.
- A nonempty input describes one valid rooted binary tree: the root has no parent, every other node has exactly one parent, and all nodes are reachable from the root. The root may have any table index. An empty tree uses root index `-1`.
- The function returns the number of levels. It writes node values in breadth-first order and writes cumulative offsets delimiting each level, beginning with offset `0`. An empty tree returns zero levels and writes the single offset `0`.
- The output-value buffer must hold one value per node, the offset buffer must hold at least `node_count + 1` entries, and the queue buffer must hold `node_count` indices. Invalid roots return `-1`; insufficient buffers return `-2` without modifying the output arrays.
- Input, output, offsets, and queue storage are supplied by the caller. The traversal itself does not allocate memory.

The shared C ABI uses the same flattened node triplets in every language. The checker compares both the complete value order and every level boundary against an independent breadth-first oracle.

## Workload and verification

`workload.json` covers empty and singleton trees, complete and sparse trees, left and right chains, repeated and signed-boundary values, and a tree whose root has a nonzero index. The verifier also checks every ordered binary-tree shape through seven nodes, deterministic random trees, trees with up to 2,047 nodes, invalid roots, and undersized output/workspace buffers.

Build with the `tree_level_order` ABI family and record with `benchmarks/run_tree_level_order.py`. `benchmarks/verify_tree_level_order.py` checks all nine language ports and their workload records.
