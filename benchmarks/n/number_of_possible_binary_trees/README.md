# Number of possible binary trees

This benchmark implements the pinned Python file's `binary_tree_count(n)`, which multiplies the Catalan number for `n` nodes by `n!`. Its `catalan_number` helper is the ordinary Catalan sequence and is covered separately by the existing `catalan_number` benchmark.

## Contract

- The scalar ABI accepts a node count `n` in `[1, 14]`.
- The pinned helper returns `1` for `n = 0`, but the source CLI rejects nonpositive node counts; this benchmark follows the CLI's positive-node domain and excludes the empty-tree case.
- The result is `binomial(2n, n) // (n + 1) * n!`, preserving the source's interleaved binomial multiply/divide and factorial product.
- Counts above 14 exceed the signed 64-bit result range; invalid inputs return `-1`.

[`workload.json`](workload.json) covers the source examples, small counts, and both domain bounds.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/n/number_of_possible_binary_trees.c`](../../../c/n/number_of_possible_binary_trees.c) |
| C3 | [`c3/n/number_of_possible_binary_trees.c3`](../../../c3/n/number_of_possible_binary_trees.c3) |
| C++ | [`cpp/n/number_of_possible_binary_trees.cpp`](../../../cpp/n/number_of_possible_binary_trees.cpp) |
| Elisa | [`elisa/n/number_of_possible_binary_trees.elisa`](../../../elisa/n/number_of_possible_binary_trees.elisa) |
| Nim | [`nim/n/number_of_possible_binary_trees.nim`](../../../nim/n/number_of_possible_binary_trees.nim) |
| Odin | [`odin/n/number_of_possible_binary_trees.odin`](../../../odin/n/number_of_possible_binary_trees.odin) |
| Rust | [`rust/n/number_of_possible_binary_trees.rs`](../../../rust/n/number_of_possible_binary_trees.rs) |
| V | [`v/n/number_of_possible_binary_trees.v`](../../../v/n/number_of_possible_binary_trees.v) |
| Zig | [`zig/n/number_of_possible_binary_trees.zig`](../../../zig/n/number_of_possible_binary_trees.zig) |

## Upstream source

- [TheAlgorithms/Python `number_of_possible_binary_trees.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/number_of_possible_binary_trees.py)
