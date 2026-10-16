# Red-black tree insertion and exact-key search

This package follows the pinned Zig `Tree(T)` implementation's ordered red-black insertion and search behavior. It uses signed 32-bit integer keys. The source does not expose deletion or traversal, so the ABI adapter returns the final key set in sorted order along with membership results from each search.

## Contract

The `i64_array_bytes_output` ABI receives `[operation_count, (opcode, key)...]`. The operation count is 0 through 128, and every key must fit a signed 32-bit integer. Operation `0` inserts a key that is not already present; operation `1` searches for a key, whether present or absent. Duplicate-key inserts are invalid. The input length must be exactly `1 + 2 * operation_count`, at most 257 signed 64-bit values.

Output is a little-endian signed i64 vector `[sorted_key_count, sorted_final_keys..., search_count, search_results...]`. Search results are `1` for present and `0` for absent, in input order. Keys are unique, so the maximum output is `8 * (2 + 128) = 1,040` bytes. The function returns the number of output bytes. Malformed input returns `-1`; null or insufficient output capacity returns `-2` without writing output.

The Zig source overwrites an existing key on duplicate insertion. The workload uses absent-key inserts to define a unique-key set trace and makes each insertion's effect unambiguous. The final sorted key list is adapter output; no internal tree shape is compared.

## Workload

[`workload.json`](workload.json) covers empty traces, searches before and after insertion, ascending, descending, and mixed insertion orders, signed i32 boundary keys, a maximum-length trace, duplicate insertions, malformed pairs, and invalid keys.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm red_black_tree_insert_search --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/r/red_black_tree_insert_search/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm red_black_tree_insert_search --languages rust
```

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/r/red_black_tree_insert_search.c`](../../../c/r/red_black_tree_insert_search.c) |
| C3 | [`c3/r/red_black_tree_insert_search.c3`](../../../c3/r/red_black_tree_insert_search.c3) |
| C++ | [`cpp/r/red_black_tree_insert_search.cpp`](../../../cpp/r/red_black_tree_insert_search.cpp) |
| Elisa | [`elisa/r/red_black_tree_insert_search.elisa`](../../../elisa/r/red_black_tree_insert_search.elisa) |
| Nim | [`nim/r/red_black_tree_insert_search.nim`](../../../nim/r/red_black_tree_insert_search.nim) |
| Odin | [`odin/r/red_black_tree_insert_search.odin`](../../../odin/r/red_black_tree_insert_search.odin) |
| Rust | [`rust/r/red_black_tree_insert_search.rs`](../../../rust/r/red_black_tree_insert_search.rs) |
| V | [`v/r/red_black_tree_insert_search.v`](../../../v/r/red_black_tree_insert_search.v) |
| Zig | [`zig/r/red_black_tree_insert_search.zig`](../../../zig/r/red_black_tree_insert_search.zig) |

## Pinned source

- Zig [`redBlackTrees.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/search/redBlackTrees.zig)
- C++ [`rb_tree.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/rb_tree.cpp) and Go [`rbtree.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/structure/tree/rbtree.go) expose red-black insertion and exact-key search. The shared contract restricts traces to unique-key insertions and searches; it does not measure their additional deletion or traversal methods.
