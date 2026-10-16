# Floor and ceiling in a binary search tree

For a query key, return both the greatest tree value less than or equal to the key (floor) and the least tree value greater than or equal to the key (ceiling). The source follows one BST search path and updates the best candidate for each side. An exact match is both results.

## Contract

- Input is packed as `[node_count, root_index, key, (value, left_index, right_index)*]`. Child indexes are zero-based; `-1` marks a missing child. A zero-node tree uses root index `-1`.
- The table represents one valid strict binary search tree with unique node values; every node is reachable from the root exactly once. There are 0 to 127 nodes. Values and query keys are in `[-1,000,000, 1,000,000]`.
- Output is 16 bytes: floor then ceiling, each a little-endian signed 64-bit integer. A missing floor or ceiling uses `INT64_MIN`, which cannot collide with an allowed node value. The empty tree returns two missing-value sentinels.
- Invalid packing, root, key, or an out-of-range node/link encountered on the search path returns `-1`. A null or short output buffer returns `-2`. Success returns 16.
- The tree structure is a valid-input precondition. Ports preserve the source's O(height) path search rather than scanning and validating every node.

The pinned Python `floor_ceiling` returns a pair of optional integers. The integer sentinel is the portable representation of `None` for this bounded domain. This algorithm is distinct from the numeric `floor` operation and from `ceil_in_binary_search_tree`, which returns only one side.

## Workload and oracle

[`workload.json`](workload.json) covers an empty tree, equality, keys between values, both out-of-range sides, negative values, valid `-1`, malformed tables, and short output capacity. The independent oracle encodes the pair as two signed 64-bit values.

Build and record with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm floor_and_ceiling --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/f/floor_and_ceiling/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm floor_and_ceiling --language rust
```

## Pinned source

[TheAlgorithms/Python `floor_and_ceiling.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/binary_tree/floor_and_ceiling.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/floor_and_ceiling.c`](../../../c/f/floor_and_ceiling.c) |
| C3 | [`c3/f/floor_and_ceiling.c3`](../../../c3/f/floor_and_ceiling.c3) |
| C++ | [`cpp/f/floor_and_ceiling.cpp`](../../../cpp/f/floor_and_ceiling.cpp) |
| Elisa | [`elisa/f/floor_and_ceiling.elisa`](../../../elisa/f/floor_and_ceiling.elisa) |
| Nim | [`nim/f/floor_and_ceiling.nim`](../../../nim/f/floor_and_ceiling.nim) |
| Odin | [`odin/f/floor_and_ceiling.odin`](../../../odin/f/floor_and_ceiling.odin) |
| Rust | [`rust/f/floor_and_ceiling.rs`](../../../rust/f/floor_and_ceiling.rs) |
| V | [`v/f/floor_and_ceiling.v`](../../../v/f/floor_and_ceiling.v) |
| Zig | [`zig/f/floor_and_ceiling.zig`](../../../zig/f/floor_and_ceiling.zig) |
