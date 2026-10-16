# Maximum Sum BST

This benchmark ports the pinned Python `max_sum_bst` traversal. It finds the largest sum among all subtrees of a binary tree that satisfy strict binary-search-tree ordering.

## Contract

The `i64_array_scalar` input is `[slot_count, slot_0, ..., slot_(n-1)]`. Slots use heap indexing: children of slot `i` are `2*i+1` and `2*i+2`. `slot_count` is 0 through 31; `-1` means an absent node, and present node values are 0 through 1,000,000. Every present node must have a present parent. The packed length must equal `slot_count + 1`.

The result is the maximum sum of any strict-BST subtree, with 0 as the baseline, matching the source for empty trees and all-zero trees. The bounded value domain is nonnegative so `-1` can encode empty slots and invalid input without colliding with a valid result. The source's full integer range, object-node API, and arbitrary tree shape are outside this compact benchmark domain.

## Source

The source is [`maximum_sum_bst.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/maximum_sum_bst.py), pinned at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. Its postorder helper returns BST validity, subtree minimum/maximum, and sum, while a separate accumulator keeps the best sum found below invalid roots. The upstream repository is licensed under [MIT](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/LICENSE).

[`workload.json`](workload.json) covers empty and full trees, strict ordering, duplicate values, null slots, best subtrees beneath invalid roots, malformed child structure, and numeric bounds. The independent oracle is [`maximum_sum_bst_oracle.py`](../../maximum_sum_bst_oracle.py).

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm maximum_sum_bst --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/m/maximum_sum_bst/rust/build.json
python3 benchmarks/verify_i64_array_scalar.py --algorithms maximum_sum_bst
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/m/maximum_sum_bst.c`](../../../c/m/maximum_sum_bst.c) |
| C3 | [`c3/m/maximum_sum_bst.c3`](../../../c3/m/maximum_sum_bst.c3) |
| C++ | [`cpp/m/maximum_sum_bst.cpp`](../../../cpp/m/maximum_sum_bst.cpp) |
| Elisa | [`elisa/m/maximum_sum_bst.elisa`](../../../elisa/m/maximum_sum_bst.elisa) |
| Nim | [`nim/m/maximum_sum_bst.nim`](../../../nim/m/maximum_sum_bst.nim) |
| Odin | [`odin/m/maximum_sum_bst.odin`](../../../odin/m/maximum_sum_bst.odin) |
| Rust | [`rust/m/maximum_sum_bst.rs`](../../../rust/m/maximum_sum_bst.rs) |
| V | [`v/m/maximum_sum_bst.v`](../../../v/m/maximum_sum_bst.v) |
| Zig | [`zig/m/maximum_sum_bst.zig`](../../../zig/m/maximum_sum_bst.zig) |
