# Binary tree path sum count

Count all downward paths whose node values add to a target. A path may start at any node and must continue from parent to child; it need not begin at the root or end at a leaf. The benchmark ports the recursive search from [TheAlgorithms Python `binary_tree_path_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/binary_tree_path_sum.py).

The source starts a downward DFS at each node, counts a match whenever the running sum equals the target, and then recursively starts the same search at each child. This differs from [`path_sum`](../../p/path_sum/README.md), which returns a boolean and only accepts root-to-leaf paths.

## Contract

- Pack input as `[target, node_count, value_0, left_0, right_0, ...]`. Node `0` is the root; child index `-1` means absent.
- There are 0 through 63 nodes. Values are signed 32-bit integers; target is signed 64-bit. Every non-root node is reachable exactly once from the root.
- Return the number of matching downward paths. Empty trees return `0`; malformed tables or tree structure return `-1`.
- This contract supplies a target on each call, matching the source's normal documented use with a fresh `BinaryTreePathSum` instance. Calling the Python method on a nonempty tree without first setting a target raises an attribute error; that default-argument behavior is outside the contract.
- Ports use the source's start-at-every-node search, with bounded recursion and path sums safely within signed 64-bit range.

The workload uses the `i64_array_scalar` ABI and `i64_array_scalar_call` comparison model.
