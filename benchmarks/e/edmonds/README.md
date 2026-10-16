# Edmonds minimum spanning arborescence

Find the minimum total weight of a directed spanning arborescence rooted at the supplied vertex (Chu–Liu/Edmonds). This is distinct from Edmonds blossom matching and Edmonds–Karp maximum flow.

Input is `[vertex_count, root, edge_count, from, to, weight, ...]`. Vertices are `0..n-1`; n is 1–5, edge count is 0–12, and edge weights are integers 0–100. Self-loops and edges entering the root cannot be part of an arborescence and are ignored. Parallel edges are allowed. Return the minimum total weight, 0 for a single vertex, and -1 for malformed input or when no rooted spanning arborescence exists. The independent oracle exhaustively selects one incoming edge per non-root vertex and rejects parent cycles.

The pinned Java source is `src/main/java/com/thealgorithms/graph/Edmonds.java` at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. It selects minimum incoming edges and contracts directed cycles; it is Chu–Liu/Edmonds, not general-graph matching.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/e/edmonds.c](../../../c/e/edmonds.c) |
| C3 | [c3/e/edmonds.c3](../../../c3/e/edmonds.c3) |
| C++ | [cpp/e/edmonds.cpp](../../../cpp/e/edmonds.cpp) |
| Elisa | [elisa/e/edmonds.elisa](../../../elisa/e/edmonds.elisa) |
| Nim | [nim/e/edmonds.nim](../../../nim/e/edmonds.nim) |
| Odin | [odin/e/edmonds.odin](../../../odin/e/edmonds.odin) |
| Rust | [rust/e/edmonds.rs](../../../rust/e/edmonds.rs) |
| V | [v/e/edmonds.v](../../../v/e/edmonds.v) |
| Zig | [zig/e/edmonds.zig](../../../zig/e/edmonds.zig) |
