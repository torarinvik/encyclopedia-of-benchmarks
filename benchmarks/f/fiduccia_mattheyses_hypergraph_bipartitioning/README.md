# Fiduccia–Mattheyses hypergraph bipartitioning

This bounded profile applies FM passes to an unweighted hypergraph. A net is
cut when it contains vertices from both blocks. Each pass locks one vertex per
move, selects by gain buckets, records the earliest best prefix, and accepts a
prefix only when it lowers the cut-net count. Repeated nets are distinct nets.

Input is `[n,m,initial_mask,(degree,sorted_vertex_ids...)*m]`. `n` is even in
4..8, `m` is 0..12, and the mask assigns exactly half the vertices to block A.
Each net contains 2..n distinct increasing vertex IDs in `0..n-1`. During a
pass, block A's size stays in `[n/2-1,n/2+1]`. A legal move's gain is the
reduction in cut-net count; choose maximum gain, including nonpositive gains.
Ties choose the smaller resulting `abs(2*size_A-n)`, then the lower vertex ID.
Continue until no legal unlocked move remains. Track prefix zero as well as
every move, keeping the earliest prefix with a strictly smaller cut count.
Repeat passes until a full pass gives no strict improvement.

The scalar result is `(cut_net_count << 8) | final_mask`. Invalid framing or
fields, a null input, and trailing words return `-1`. Maximum valid input is
111 i64 words; 112 are parseable to detect a trailing word. The result is at
most 3327.

The primary oracle recomputes each vertex's gain from its incident nets. The
independent oracle fully recounts cut nets for every candidate move. Ports
rebuild bounded gain buckets after each move to keep the ordering explicit;
this profile emphasizes deterministic FM semantics over large-hypergraph
throughput. A pass takes O(m n^3) time in ports that rescan each net's pins,
and O(m n^2) in ports that keep each net as a vertex mask; at most m improving
passes and one terminal pass give a conservative O(m^2 n^3) worst-case time
bound. Workspace is O(m n+n). Both oracles and supplied fixtures are source
data, not timed code.

The method is based on C. M. Fiduccia and R. M. Mattheyses, “A Linear-Time
Heuristic for Improving Network Partitions,” DAC 1982. The algorithmic idea is
used with an independently authored contract and implementation; no source
code or explanatory prose is copied. See [`RIGHTS.md`](RIGHTS.md).

ABI: `i64_array_scalar`, symbol `fiduccia_mattheyses_hypergraph_bipartitioning`.

| Language | Port |
|---|---|
| C | `c/f/fiduccia_mattheyses_hypergraph_bipartitioning.c` |
| C3 | `c3/f/fiduccia_mattheyses_hypergraph_bipartitioning.c3` |
| C++ | `cpp/f/fiduccia_mattheyses_hypergraph_bipartitioning.cpp` |
| Elisa | `elisa/f/fiduccia_mattheyses_hypergraph_bipartitioning.elisa` |
| Mojo | `mojo/f/fiduccia_mattheyses_hypergraph_bipartitioning.mojo` |
| Nim | `nim/f/fiduccia_mattheyses_hypergraph_bipartitioning.nim` |
| Odin | `odin/f/fiduccia_mattheyses_hypergraph_bipartitioning.odin` |
| Rust | `rust/f/fiduccia_mattheyses_hypergraph_bipartitioning.rs` |
| V | `v/f/fiduccia_mattheyses_hypergraph_bipartitioning.v` |
| Zig | `zig/f/fiduccia_mattheyses_hypergraph_bipartitioning.zig` |
