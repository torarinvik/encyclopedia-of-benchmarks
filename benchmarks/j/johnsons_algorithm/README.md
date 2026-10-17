# Johnson's algorithm

This package follows the pinned Java implementation of Johnson's all-pairs shortest-path algorithm. The source entry point is `johnsonAlgorithm(double[][])`; the benchmark adapter is named `johnsons_algorithm`.

## Contract

The benchmark uses the `i64_array_scalar` ABI. Input is `[V, row-major V×V matrix]`, with `1 <= V <= 16`, exactly `1 + V*V` signed-i64 words, and each matrix cell in `[-32, 32]`. A zero cell means no edge. Every nonzero off-diagonal cell is a directed edge with that weight. Diagonal cells are ignored because the pinned edge-list conversion excludes self-loops. The adapters normalize zero cells to positive infinity before edge-list construction and before reweighting or Dijkstra, so zero remains an absent-edge marker throughout the graph pipeline.

The accepted graph must be strongly connected (a one-vertex graph is strongly connected), contain no negative cycle, and have strictly positive reduced weight `w + h[u] - h[v]` on every ingested edge, using the pinned Bellman-Ford potentials. Disconnected graphs are outside the contract because the pinned Dijkstra selector returns `-1` when no reachable vertex remains. Zero reduced edges are also outside the contract because the pinned Dijkstra implementation treats a zero reweighted matrix cell as absent. A null input pointer with positive declared length, invalid shape, cell range, connectivity, negative cycle, or reduced-edge condition returns `-1`. The maximum non-null input contains 257 words.

The scalar result is the low 63 bits of FNV-1a-64 over the `V×V` shortest-distance matrix in row-major order. Each distance is encoded as one little-endian signed-i64 word. Finite distances are exact integers in this bounded workload. Java `Double.POSITIVE_INFINITY` is reserved as `2^62` in the hash stream; strongly connected valid inputs do not produce unreachable pairs. The offset basis is `14695981039346656037` and the prime is `1099511628211`.

The independent Floyd-Warshall oracle is [johnsons_algorithm_oracle.py](../../johnsons_algorithm_oracle.py). The workload covers directed paths and shortcuts, ignored diagonal self-loops, zero-as-absent cells, maximum matrix size, null and malformed inputs, disconnected graphs, negative cycles, and zero-reweighted edges.

Pinned source: [TheAlgorithms/Java `JohnsonsAlgorithm.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/graphs/JohnsonsAlgorithm.java).

## Implementations

| Language | Port |
|---|---|
| C | [c/j/johnsons_algorithm.c](../../../c/j/johnsons_algorithm.c) |
| C3 | [c3/j/johnsons_algorithm.c3](../../../c3/j/johnsons_algorithm.c3) |
| C++ | [cpp/j/johnsons_algorithm.cpp](../../../cpp/j/johnsons_algorithm.cpp) |
| Elisa | [elisa/j/johnsons_algorithm.elisa](../../../elisa/j/johnsons_algorithm.elisa) |
| Nim | [nim/j/johnsons_algorithm.nim](../../../nim/j/johnsons_algorithm.nim) |
| Odin | [odin/j/johnsons_algorithm.odin](../../../odin/j/johnsons_algorithm.odin) |
| Rust | [rust/j/johnsons_algorithm.rs](../../../rust/j/johnsons_algorithm.rs) |
| V | [v/j/johnsons_algorithm.v](../../../v/j/johnsons_algorithm.v) |
| Zig | [zig/j/johnsons_algorithm.zig](../../../zig/j/johnsons_algorithm.zig) |

Build and record with the `i64_array_scalar` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm johnsons_algorithm --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --algorithm johnsons_algorithm
python3 benchmarks/verify_i64_array_scalar.py --algorithm johnsons_algorithm --languages rust
```
