# Minimal dominating sets in interval graphs

This profile counts minimal dominating sets of a bounded interval graph using
the source-described pair-state DAG. It is the interval-graph case from DOI
721, not the general minimal-dominating-set enumeration problem.

## Contract

Input is `[n, start_0, end_0, ..., start_(n-1), end_(n-1)]`, with `1 <= n <=
12`. Intervals are closed, have distinct integer endpoints in `[-100,100]`,
and are ordered by strictly increasing starts. The implementation computes
the interval graph implicitly. It constructs valid pair nodes `(i,j)` using
the source's prefix-private-neighbor and next-component endpoint tests, adds
arcs `(i,j)->(j,k)` by the source's private-neighbor extension test, then
counts paths from initial to final pair nodes. Dominating singleton intervals
are counted separately. Output is one signed-i64 count in eight little-endian
bytes. Invalid input returns `-1`; null output or capacity below eight bytes
returns `-2`, after input validation. Errors do not write output.

## Source scope

- Encyclopedia of Algorithms DOI `10.1007/978-1-4939-2864-4_721`,
  `OEBPS/AChap721.html`, which gives the interval-graph pair-DAG construction
  and path-counting reduction.
- Kanté, Limouzy, Mary, Nourine, and Uno, “On the Enumeration and Counting of
  Minimal Dominating sets in Interval and Permutation Graphs,” DOI
  `10.1007/978-3-642-45030-3_32` ([paper PDF](https://perso.limos.fr/~limouzy/papers/ISAAC2013-2.pdf)); its interval-graph propositions specify the exact node, arc, source, and sink predicates used here.

The source's permutation-graph algorithm, general-graph output-polynomial
question, and enumeration output itself are outside this count-only bounded
profile. The primary oracle implements the pair-DAG recurrence; the independent
verifier exhaustively checks every vertex subset and its private-neighbor
minimality. See [`workload.json`](workload.json),
[`benchmarks/minimal_dominating_sets_interval_oracle.py`](../../minimal_dominating_sets_interval_oracle.py),
and [`benchmarks/minimal_dominating_sets_interval_verifier_oracle.py`](../../minimal_dominating_sets_interval_verifier_oracle.py).

## Rights

The ports are clean-room implementations of the cited algorithmic predicates.
No paper code, book prose, or figures are copied; the cited publication is an
algorithm reference, not a source-code license.

## Ports

| Language | Port |
|---|---|
| C | [`c/m/minimal_dominating_sets_interval.c`](../../../c/m/minimal_dominating_sets_interval.c) |
| C3 | [`c3/m/minimal_dominating_sets_interval.c3`](../../../c3/m/minimal_dominating_sets_interval.c3) |
| C++ | [`cpp/m/minimal_dominating_sets_interval.cpp`](../../../cpp/m/minimal_dominating_sets_interval.cpp) |
| Elisa | [`elisa/m/minimal_dominating_sets_interval.elisa`](../../../elisa/m/minimal_dominating_sets_interval.elisa) |
| Nim | [`nim/m/minimal_dominating_sets_interval.nim`](../../../nim/m/minimal_dominating_sets_interval.nim) |
| Odin | [`odin/m/minimal_dominating_sets_interval.odin`](../../../odin/m/minimal_dominating_sets_interval.odin) |
| Rust | [`rust/m/minimal_dominating_sets_interval.rs`](../../../rust/m/minimal_dominating_sets_interval.rs) |
| V | [`v/m/minimal_dominating_sets_interval.v`](../../../v/m/minimal_dominating_sets_interval.v) |
| Zig | [`zig/m/minimal_dominating_sets_interval.zig`](../../../zig/m/minimal_dominating_sets_interval.zig) |
