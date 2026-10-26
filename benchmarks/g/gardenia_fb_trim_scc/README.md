# GARDENIA Forward–Backward–Trim strongly connected components

This clean-room package profiles GARDENIA's documented FB-Trim SCC kernel at
[`chenxuhao/gardenia`](https://github.com/chenxuhao/gardenia) commit
[`5894df11cf47f8839945edadff43dc79e260216d`](https://github.com/chenxuhao/gardenia/tree/5894df11cf47f8839945edadff43dc79e260216d).
The OpenMP `src/scc/omp_base.cc` file is a stub; the source algorithm is in
`src/scc/base.cu`, described by `src/scc/scc.h`, and launched from
`src/scc/main.cc`.

## Bounded profile

Input is `[n, m, (u, v)...]` for a directed simple graph with `1<=n<=16` and
`0<=m<=64`. Directed self-loops are allowed; repeated arcs and endpoints
outside `[0,n)` are rejected. Each call starts from an unmarked graph. It
repeatedly trims active vertices with zero active in-degree or zero active
out-degree as singleton SCCs. In each remaining subgraph, it selects the
lowest-ID pivot, computes forward and reverse reachability, emits their
intersection as one SCC, then recursively processes the forward-only,
backward-only, and neither-reachable subgraphs. This is a deterministic
single-pivot projection of Gardenia's FB-Trim reachability, trimming, and
subgraph-color split; the CUDA pivot hash/scheduling and color encoding are
replaced by an explicit smallest-ID pivot and canonical component labels.

Output is one little-endian signed i64 per vertex: the minimum vertex ID in
that vertex's SCC. Malformed input returns `-1`; null or short output returns
`-2` without writing. The independent verifier computes mutual reachability
closure, not FB-Trim.

The pinned repository's MIT notice is retained in [`LICENSE.txt`](LICENSE.txt).
The nine clean-room ports are listed below.

| Language | Source |
|---|---|
| C | [`c/g/gardenia_fb_trim_scc.c`](../../../c/g/gardenia_fb_trim_scc.c) |
| C3 | [`c3/g/gardenia_fb_trim_scc.c3`](../../../c3/g/gardenia_fb_trim_scc.c3) |
| C++ | [`cpp/g/gardenia_fb_trim_scc.cpp`](../../../cpp/g/gardenia_fb_trim_scc.cpp) |
| Elisa | [`elisa/g/gardenia_fb_trim_scc.elisa`](../../../elisa/g/gardenia_fb_trim_scc.elisa) |
| Nim | [`nim/g/gardenia_fb_trim_scc.nim`](../../../nim/g/gardenia_fb_trim_scc.nim) |
| Odin | [`odin/g/gardenia_fb_trim_scc.odin`](../../../odin/g/gardenia_fb_trim_scc.odin) |
| Rust | [`rust/g/gardenia_fb_trim_scc.rs`](../../../rust/g/gardenia_fb_trim_scc.rs) |
| V | [`v/g/gardenia_fb_trim_scc.v`](../../../v/g/gardenia_fb_trim_scc.v) |
| Zig | [`zig/g/gardenia_fb_trim_scc.zig`](../../../zig/g/gardenia_fb_trim_scc.zig) |

The package oracle is [`gardenia_fb_trim_scc_oracle.py`](../../gardenia_fb_trim_scc_oracle.py);
the independently structured verifier oracle is
[`gardenia_fb_trim_scc_verifier_oracle.py`](../../gardenia_fb_trim_scc_verifier_oracle.py).
