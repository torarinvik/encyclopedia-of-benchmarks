# Union-find with potential

This benchmark maintains modular difference constraints with a disjoint-set
union structure whose parent edges carry relative potentials.

## Contract

The official task has an unknown sequence `a[0..N)`, with modulus
`998244353`. An update provides `a[u] - a[v] = x (mod MOD)`. It is accepted
and outputs `1` if it agrees with every previously accepted constraint; a
contradiction is rejected with `0` and leaves the structure unchanged. A query
outputs `a[u] - a[v] (mod MOD)` when determined, or `-1` when the vertices are
in different components.

The bounded ABI uses `[N, Q, (type, u, v, x)...]`; each operation occupies four
signed 64-bit values. Type `0` is an update. Type `1` is a query and requires
the unused `x` field to be zero. The profile limits `1 <= N <= 64` and
`1 <= Q <= 256`. Indices must be in `[0,N)`, and update values must be in
`[0,MOD)`. Invalid input returns `-1`. Successful calls write one signed
64-bit little-endian result per operation and return the number of bytes
written. A null or undersized output buffer returns `-2` without writing.

The implementation uses path compression and union by size. For an update
`a[u]-a[v]=x`, it checks the existing potential difference when the endpoints
are connected; otherwise it links the two roots with the derived relative
offset. Each operation is amortized inverse-Ackermann time.

## Distinctness

The local [`union_find`](../union_find/README.md) benchmark tracks only
connectivity and component sizes; it has no modular weights or contradiction
handling. The local [`potential_energy`](../../p/potential_energy/README.md)
benchmark is a physical formula (`mass * gravity * height`) and is unrelated
to DSU potentials.

Official contract: [Library Checker — Unionfind with Potential](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/unionfind_with_potential/task.md)
with limits from its [info.toml](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/unionfind_with_potential/info.toml).

## Workload and oracle

[`workload.json`](workload.json) covers disconnected queries, transitive
constraints, consistent and contradictory cycles, self-relations, modular
wraparound, malformed records, and short output capacity. The independent
oracle [`benchmarks/unionfind_with_potential_oracle.py`](../../unionfind_with_potential_oracle.py)
uses graph traversal over accepted equations rather than a disjoint-set
structure.

## Implementations

| Language | Port |
|---|---|
| C | [`c/u/unionfind_with_potential.c`](../../../c/u/unionfind_with_potential.c) |
| C3 | [`c3/u/unionfind_with_potential.c3`](../../../c3/u/unionfind_with_potential.c3) |
| C++ | [`cpp/u/unionfind_with_potential.cpp`](../../../cpp/u/unionfind_with_potential.cpp) |
| Elisa | [`elisa/u/unionfind_with_potential.elisa`](../../../elisa/u/unionfind_with_potential.elisa) |
| Nim | [`nim/u/unionfind_with_potential.nim`](../../../nim/u/unionfind_with_potential.nim) |
| Odin | [`odin/u/unionfind_with_potential.odin`](../../../odin/u/unionfind_with_potential.odin) |
| Rust | [`rust/u/unionfind_with_potential.rs`](../../../rust/u/unionfind_with_potential.rs) |
| V | [`v/u/unionfind_with_potential.v`](../../../v/u/unionfind_with_potential.v) |
| Zig | [`zig/u/unionfind_with_potential.zig`](../../../zig/u/unionfind_with_potential.zig) |
| Mojo | [`mojo/u/unionfind_with_potential.mojo`](../../../mojo/u/unionfind_with_potential.mojo) |
