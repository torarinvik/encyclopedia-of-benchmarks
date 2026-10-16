# Hopcroft–Karp matching cardinality

This benchmark computes the maximum cardinality matching of a bipartite graph. It compares only the matching size, since valid algorithms can return different maximum matchings. The pinned source families are C++, Java, and Python. The C++ source class uses 1-based partition labels; the shared contract normalizes input to zero-based IDs. The Python source returns a matching map; this contract reports its cardinality.

## Contract

Input is a packed signed 64-bit vector `[left_count, right_count, edge_count, (left, right)...]`. Each partition contains 0 through 64 vertices, and there are 0 through 4,096 edge records. Endpoints use zero-based IDs within their respective partitions. The namespaces are separate, so left vertex 0 and right vertex 0 are distinct. Duplicate edges are accepted and treated as a single adjacency. The packed length must equal `3 + 2 * edge_count`.

The function returns the maximum number of pairwise vertex-disjoint edges. Empty partitions and isolated vertices are allowed. The Python adapter keeps left and right vertex namespaces distinct. Malformed counts, lengths, or endpoints return `-1`.

The workload covers empty partitions, unequal sizes, augmenting-path reassignment, duplicates, isolated vertices, invalid inputs, and the complete 64-by-64 graph at the edge bound.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm hopcroft_karp_cardinality --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/h/hopcroft_karp_cardinality/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hopcroft_karp_cardinality.c`](../../../c/h/hopcroft_karp_cardinality.c) |
| C3 | [`c3/h/hopcroft_karp_cardinality.c3`](../../../c3/h/hopcroft_karp_cardinality.c3) |
| C++ | [`cpp/h/hopcroft_karp_cardinality.cpp`](../../../cpp/h/hopcroft_karp_cardinality.cpp) |
| Elisa | [`elisa/h/hopcroft_karp_cardinality.elisa`](../../../elisa/h/hopcroft_karp_cardinality.elisa) |
| Nim | [`nim/h/hopcroft_karp_cardinality.nim`](../../../nim/h/hopcroft_karp_cardinality.nim) |
| Odin | [`odin/h/hopcroft_karp_cardinality.odin`](../../../odin/h/hopcroft_karp_cardinality.odin) |
| Rust | [`rust/h/hopcroft_karp_cardinality.rs`](../../../rust/h/hopcroft_karp_cardinality.rs) |
| V | [`v/h/hopcroft_karp_cardinality.v`](../../../v/h/hopcroft_karp_cardinality.v) |
| Zig | [`zig/h/hopcroft_karp_cardinality.zig`](../../../zig/h/hopcroft_karp_cardinality.zig) |

## Pinned source references

- C++: [`hopcroft_karp.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/graph/hopcroft_karp.cpp)
- C++ mirror: [`hopcroft_karp.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/graph/hopcroft_karp.cpp)
- Java: [`HopcroftKarp.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/graph/HopcroftKarp.java)
- Python: [`hopcroft_karp.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphs/hopcroft_karp.py)
