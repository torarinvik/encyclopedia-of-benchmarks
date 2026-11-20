# Schorr–Waite graph marking

Input is `[N,root,(left_i,right_i)*N]` for a directed ordered binary graph with 1..32 nodes. Each edge is `-1` or a node index. Cycles, self-loops, shared children, and unreachable nodes are allowed. The result is an integer bitset with bit `i` set exactly for nodes reachable from `root`; invalid input returns `-1`.

The language ports use pointer reversal: they temporarily encode return paths in child slots, mark visited nodes, and restore the original edges as the traversal unwinds. This handles cycles and aliases without an explicit depth-sized traversal stack. The two simple package references use a stack and a queue respectively; they provide independent reachability results. Graph copies and per-node marks/phases use `O(N)` bounded storage, while traversal control uses a constant number of scalar variables.

This differs from ordinary depth-first and breadth-first marking, which retain a stack or queue. NIST describes the pointer-reversal traversal in its [Schorr–Waite graph marking entry](https://xlinux.nist.gov/dads/HTML/SchorrWaiteGraphMarking.html); a verified specification is available from [Why3/Toccata](https://toccata.gitlabpages.inria.fr/toccata/gallery/schorr_waite.en.html). The package uses the algorithm and postcondition ideas only; its code, input contract, and fixtures are independently written.

| Language | Port |
|---|---|
| C | [c/s/schorr_waite_graph_marking.c](../../../c/s/schorr_waite_graph_marking.c) |
| C3 | [c3/s/schorr_waite_graph_marking.c3](../../../c3/s/schorr_waite_graph_marking.c3) |
| C++ | [cpp/s/schorr_waite_graph_marking.cpp](../../../cpp/s/schorr_waite_graph_marking.cpp) |
| Elisa | [elisa/s/schorr_waite_graph_marking.elisa](../../../elisa/s/schorr_waite_graph_marking.elisa) |
| Mojo | [mojo/s/schorr_waite_graph_marking.mojo](../../../mojo/s/schorr_waite_graph_marking.mojo) |
| Nim | [nim/s/schorr_waite_graph_marking.nim](../../../nim/s/schorr_waite_graph_marking.nim) |
| Odin | [odin/s/schorr_waite_graph_marking.odin](../../../odin/s/schorr_waite_graph_marking.odin) |
| Rust | [rust/s/schorr_waite_graph_marking.rs](../../../rust/s/schorr_waite_graph_marking.rs) |
| V | [v/s/schorr_waite_graph_marking.v](../../../v/s/schorr_waite_graph_marking.v) |
| Zig | [zig/s/schorr_waite_graph_marking.zig](../../../zig/s/schorr_waite_graph_marking.zig) |
