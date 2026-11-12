# Counting Eulerian Circuits

Count edge-labeled directed Eulerian circuits modulo `998244353`, treating
cyclic shifts as the same circuit. The contract follows the [Library Checker
task](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/counting_eulerian_circuits/task.md);
its official bounds are in the matching
[info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/graph/counting_eulerian_circuits/info.toml).
Only the task definition is used. The ports and oracle here are independently
written.

## Contract

The `i64_array_bytes_output` input is `[n, m, (u, v)*m]`. Vertices are numbered
from zero. The official task allows `1 <= n <= 500` and `1 <= m <= 200000`;
this local benchmark narrows the bounds to `1 <= n <= 7` and `1 <= m <= 9` so
the independent edge-order oracle can enumerate every candidate ordering.
Each directed edge is identified by its input index. Parallel edges and
self-loops are allowed and remain distinct.
The result counts edge sequences that use every edge exactly once, with edge
zero fixed as the first edge; this is equivalent to counting circuits up to
cyclic shift. A graph with no Eulerian circuit has count zero. The count is
encoded as an unsigned 64-bit integer in eight little-endian bytes. Invalid
input returns `-1`; a null output pointer or capacity below eight bytes returns
`-2`. Input validation precedes output errors, and failures write no bytes.

## Algorithm and bounds

The implementation first checks equality of in-degree and out-degree at every
active vertex. It then applies the BEST theorem: for the start vertex of edge
zero, multiply the number of directed spanning arborescences oriented toward
that root by `product((outdegree(v) - 1)!)` over active vertices. The arborescence
count is a directed Matrix-Tree cofactor determinant, computed by modular
Gaussian elimination. Isolated vertices are omitted from the cofactor. The
runtime is `O(n^3 + m)` with `O(n^2)` working space.

This is a counting algorithm rather than the existing Eulerian path/trail
packages, which construct one route. It also uses the existing directed
Matrix-Tree method as a component, but adds the BEST-theorem circuit count and
degree factorial product. The independent oracle enumerates edge-index orders
with edge zero fixed first, preserving parallel-edge identity. Its worst-case
search is bounded by `8!` orders.

See [`workload.json`](workload.json) and the independent
[edge-order enumeration oracle](../../counting_eulerian_circuits_oracle.py).
No implementation has been run or compiled.

## Language ports

| Language | Source |
|---|---|
| C | [`c/g/counting_eulerian_circuits.c`](../../../c/g/counting_eulerian_circuits.c) |
| C3 | [`c3/g/counting_eulerian_circuits.c3`](../../../c3/g/counting_eulerian_circuits.c3) |
| C++ | [`cpp/g/counting_eulerian_circuits.cpp`](../../../cpp/g/counting_eulerian_circuits.cpp) |
| Elisa | [`elisa/g/counting_eulerian_circuits.elisa`](../../../elisa/g/counting_eulerian_circuits.elisa) |
| Nim | [`nim/g/counting_eulerian_circuits.nim`](../../../nim/g/counting_eulerian_circuits.nim) |
| Odin | [`odin/g/counting_eulerian_circuits.odin`](../../../odin/g/counting_eulerian_circuits.odin) |
| Rust | [`rust/g/counting_eulerian_circuits.rs`](../../../rust/g/counting_eulerian_circuits.rs) |
| V | [`v/g/counting_eulerian_circuits.v`](../../../v/g/counting_eulerian_circuits.v) |
| Zig | [`zig/g/counting_eulerian_circuits.zig`](../../../zig/g/counting_eulerian_circuits.zig) |
| Mojo | [`mojo/g/counting_eulerian_circuits.mojo`](../../../mojo/g/counting_eulerian_circuits.mojo) |
