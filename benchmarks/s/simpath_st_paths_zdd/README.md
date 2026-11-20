# Simpath construction of an s–t path ZDD

The package constructs a zero-suppressed decision diagram for every simple
undirected path between two supplied vertices. Input is
`[n,m,source,target,(u,v)*m]`: `2<=n<=8`, `0<=m<=9`, distinct in-range
terminals, and unique undirected edges encoded with `u<v`. The input edge order
is the decision-variable order. The frame must contain exactly `4+2m` signed
64-bit words; the maximum valid and parseable lengths are 22 and 23 words.
Malformed input returns `-1`.

The scalar result is `2048 * zdd_node_count + path_count`. `zdd_node_count`
counts nonterminal nodes reachable from the reduced ZDD root; terminals are
not counted. `path_count` is the number of represented source-to-target paths.
The radix 2048 exceeds the maximum number of simple paths between two vertices
in any eight-vertex simple graph (1957). An empty family returns zero. For at
most nine variables, the ZDD contains at most 511 nonterminal nodes, so the
summary is exact and bounded.

The primary follows the chapter's frontier/mate approach. It processes edges
in the supplied order, stores each selected partial path as endpoint mates,
and merges equivalent suffix states. This bounded implementation evaluates
the layer-indexed state graph in recursive postorder rather than materializing
the chapter's breadth-first intermediate graph; the state equivalence and
terminal decisions are the same, and the reduced ZDD is canonical. It rejects degree violations, cycle
closures, nonterminal path fragments that leave the frontier, and terminals
that leave without an incident selected edge. When one selected fragment
connects the source and target and no other path fragment remains, that branch
reaches the one-terminal. A bottom-up unique table merges identical
`(edge,low,high)` nodes and applies ZDD zero suppression (`high=0` returns
`low`). The fixed profile uses at most 1023 frontier states and 511 ZDD nodes;
its declared workspace bound is 65,536 bytes. Fixed-array linear lookups make
the implementation's worst-case work `O(S^2 n + S Z)`, where `S<=1023` is the
number of memoized frontier states and `Z<=511` is the number of unique ZDD
nodes; this records the bounded ports' actual lookup cost.

The independent reference explicitly enumerates all vertex-simple paths,
turns each path into its edge subset, and recursively canonicalizes that
materialized family. It does not use mate states, frontier pruning, or Simpath's
state merging.

Chapter 734, [“Counting by ZDD”](https://doi.org/10.1007/978-1-4939-2864-4_734),
identifies Simpath as a frontier-based dynamic program for constructing an
s–t-path ZDD. Knuth gives the original algorithm in *The Art of Computer
Programming*, Vol. 4A, §7.1.4; the [official program index](https://cs.stanford.edu/~knuth/programs.html)
identifies his Simpath materials. Iwashita's [Hokkaido University technical
report](https://www-alg.ist.hokudai.ac.jp/~thomas/TCSTR/tcstr_13_69/tcstr_13_69.pdf)
describes the mate-state transition and terminal checks. Local
[`zdd_family_count`](../../z/zdd_family_count/README.md) only builds a ZDD from
an explicit family, while local path enumeration returns paths individually;
neither constructs the compressed family from graph-edge decisions. This
bounded package uses method descriptions only and contains clean-room
contracts, references, fixtures, and ports.

| Language | Source |
|---|---|
| C | [`c/s/simpath_st_paths_zdd.c`](../../../c/s/simpath_st_paths_zdd.c) |
| C3 | [`c3/s/simpath_st_paths_zdd.c3`](../../../c3/s/simpath_st_paths_zdd.c3) |
| C++ | [`cpp/s/simpath_st_paths_zdd.cpp`](../../../cpp/s/simpath_st_paths_zdd.cpp) |
| Elisa | [`elisa/s/simpath_st_paths_zdd.elisa`](../../../elisa/s/simpath_st_paths_zdd.elisa) |
| Mojo | [`mojo/s/simpath_st_paths_zdd.mojo`](../../../mojo/s/simpath_st_paths_zdd.mojo) |
| Nim | [`nim/s/simpath_st_paths_zdd.nim`](../../../nim/s/simpath_st_paths_zdd.nim) |
| Odin | [`odin/s/simpath_st_paths_zdd.odin`](../../../odin/s/simpath_st_paths_zdd.odin) |
| Rust | [`rust/s/simpath_st_paths_zdd.rs`](../../../rust/s/simpath_st_paths_zdd.rs) |
| V | [`v/s/simpath_st_paths_zdd.v`](../../../v/s/simpath_st_paths_zdd.v) |
| Zig | [`zig/s/simpath_st_paths_zdd.zig`](../../../zig/s/simpath_st_paths_zdd.zig) |

The package-local inventory helper inspects package files and workload shape
only. It does not call either reference or any compiled port.
