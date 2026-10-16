# Union-find operations

This benchmark tracks a partition of a bounded integer universe. It applies set unions, tests whether pairs are connected, reports the component count, and checks the final partition independently of representative IDs.

## Contract

- Input is `[item_count, operation_count, opcode, first, second, ...]` with one triple per operation.
- Item count is from 1 through 256; operation count is from 0 through 512.
- Opcode `0` unions the sets containing `first` and `second`. The observed value is 1 if the sets were distinct and merged, otherwise 0.
- Opcode `1` reports whether `first` and `second` are in the same set. Opcode `2` reports the component count and requires both unused fields to be zero.
- Indices for opcodes 0 and 1 must be in `[0, item_count)`. Malformed traces return `-1`.
- The signed 64-bit scalar result is a weighted checksum of per-operation results plus the number of connected unordered pairs in the final partition. Representative IDs are intentionally not part of the result, allowing union-by-rank and union-by-size implementations to agree.
- Implementations use bounded storage, union by size, and portable integer operations. Most use path halving; the Elisa version walks parent links without rewriting them. The connected-pair total is accumulated when two components merge; the universe is zero-based.

## Workload and verification

[`workload.json`](workload.json) contains valid and invalid traces, including singleton and maximum-size universes, duplicate unions, connectivity checks, and component counts. [`verify_union_find.py`](../../verify_union_find.py) compares all nine implementations with an independent partition-label oracle over exhaustive short traces, deterministic random traces, and malformed inputs.

## Reviewed TheAlgorithms sources

The candidate filenames `union_find`, `disjoint_set`, and `disjoint_set_union` describe the same partitioning algorithm in the pinned source snapshot. Their APIs and heuristics differ: some use node objects or arbitrary payloads, while others use integer indices; some count components and some do not. The benchmark normalizes these to a bounded integer universe and checks partition behavior.

- [C union-find](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/union_find.c) uses path compression and root linking.
- [Java union-find](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/searches/UnionFind.java) uses path compression and union by rank.
- [JavaScript union-find](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Search/UnionFind.js) uses path halving, union by size, and tracks component count.
- [Lua union-find](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/data_structures/union_find.lua) stores explicit member lists and merges smaller sets into larger sets.
- [Rust union-find](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/data_structures/union_find.rs) supports generic payloads, path compression, union by size, and component counts.
- [Swift union-find](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/union_find/union_find.swift) represents elements as nodes and uses path halving with union by rank.
- [Go `unionfind`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/graph/unionfind.go) initializes one parent per element, compresses paths in `Find`, and merges roots by rank in `Union`; its filename is reviewed as an alias of this benchmark under the Go repository's [MIT license](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/LICENSE).
- [C++ disjoint set](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/disjoint_set.cpp) and [its additional repository copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/disjoint_set.cpp) use path compression and union by rank over one-based indices.
- [C-Sharp disjoint set](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/DisjointSet/DisjointSet.cs), [PHP disjoint set](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/DisjointSets/DisjointSet.php), and [Python disjoint set](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/disjoint_set/disjoint_set.py) use node objects, path compression, and union by rank.
- Python [`alternate_disjoint_set.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/disjoint_set/alternate_disjoint_set.py) uses path compression and union by rank while also tracking component sizes and the largest component. It aliases this benchmark for its partition operations; the extra largest-component statistic is outside the shared contract.
- [Julia disjoint set](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/data_structures/disjoint_set/disjoint_set.jl) applies path compression and root linking; [TypeScript disjoint set](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/disjoint_set/disjoint_set.ts) uses path compression and union by size.
- [Java disjoint-set union](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/disjointsetunion/DisjointSetUnion.java) uses node objects and union by rank; [Rust disjoint-set union](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/graph/disjoint_set_union.rs) uses path compression and union by size.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `u` folder for each language.
