# Synchronous-round push–relabel maximum flow

This bounded profile simulates the synchronous-round push–relabel algorithm
described in Section 3 of Baumstark, Blelloch, and Shun. It represents the
round barriers as one deterministic call; it does not launch threads or claim
to reproduce their `prsn` optimization from Section 3.1.

## Contract

- ABI: `i64_array_scalar`, symbol `synchronous_round_push_relabel`.
- Input: `[N,M,s,t,(u,v,capacity)*M]`, exactly `4+3M` signed 64-bit words.
- `2<=N<=8`, `0<=M<=24`; vertices are zero-based, source and sink are distinct.
- Directed arcs have capacities `0..15`. Self-loops are invalid; parallel and
  antiparallel arcs are allowed and parallel capacities are summed.
- Return the maximum-flow value. Invalid or null input returns `-1`.
- The maximum valid frame has 76 words; the parseable framing cap is 77. The
  maximum result is 360, bounded by 24 source arcs of capacity 15.

## Fixed synchronous-round profile

Initialize a preflow by saturating source arcs in ascending destination order,
set the source height to `N`, and set all other heights to zero. Each round
uses the active nonterminal vertices with positive excess and height below
`N`, in ascending vertex order. In Step 1, each active vertex scans neighbors
in ascending ID order and pushes along every currently admissible residual
arc (`height[u] == height[v]+1`), using its excess from the start of the
round. Residual capacities are updated during that pass, while excess changes
are accumulated separately. This sequential simulation gives the specified
round result because opposite pushes across one residual pair cannot both be
admissible under the round's unchanged heights.

After all vertices finish Step 1, compute each still-active vertex's temporary
height as one plus the minimum old height among its positive-residual
neighbors; use `N+1` when it has no residual neighbor. Apply all temporary
heights together, then commit the excess deltas together. Repeat until there
are no active nonterminals below height `N`; the sink excess is the maximum
flow value. The profile omits optional global/gap relabeling and the paper's
Section 3.1 multi-relabel conflict-resolution optimization. These fixed
choices make the single-call result independent of thread count and scheduling.

The primary reference follows the synchronous round barriers. The independent
reference enumerates all source-containing, sink-excluding cuts and returns
the minimum directed cut capacity.

## Source and rights

- The [fcBK benchmark README](https://github.com/fcBK-maxflow/fcBK-benchmark)
  identifies `ppr` as the Baumstark–Blelloch–Shun synchronous parallel
  push–relabel method.
- Baumstark, Blelloch, and Shun, [“Efficient Implementation of a Synchronous
  Parallel Push-Relabel Algorithm”](https://doi.org/10.1007/978-3-662-48350-3_10),
  ESA 2015; [long version](https://arxiv.org/abs/1507.01926) and
  [author-hosted PDF](https://www.cs.cmu.edu/~blelloch/papers/BBS15.pdf).

Only the algorithm description is used. No upstream implementation, code,
benchmark instances, or paper prose is reproduced. See [RIGHTS](RIGHTS.md).

See the [workload](workload.json), [primary reference](primary_oracle.py),
[cut-enumeration reference](independent_oracle.py), and
[static inventory](verify_workload.py).

| Language | Port |
|---|---|
| C | [c/s/synchronous_round_push_relabel.c](../../../c/s/synchronous_round_push_relabel.c) |
| C3 | [c3/s/synchronous_round_push_relabel.c3](../../../c3/s/synchronous_round_push_relabel.c3) |
| C++ | [cpp/s/synchronous_round_push_relabel.cpp](../../../cpp/s/synchronous_round_push_relabel.cpp) |
| Elisa | [elisa/s/synchronous_round_push_relabel.elisa](../../../elisa/s/synchronous_round_push_relabel.elisa) |
| Mojo | [mojo/s/synchronous_round_push_relabel.mojo](../../../mojo/s/synchronous_round_push_relabel.mojo) |
| Nim | [nim/s/synchronous_round_push_relabel.nim](../../../nim/s/synchronous_round_push_relabel.nim) |
| Odin | [odin/s/synchronous_round_push_relabel.odin](../../../odin/s/synchronous_round_push_relabel.odin) |
| Rust | [rust/s/synchronous_round_push_relabel.rs](../../../rust/s/synchronous_round_push_relabel.rs) |
| V | [v/s/synchronous_round_push_relabel.v](../../../v/s/synchronous_round_push_relabel.v) |
| Zig | [zig/s/synchronous_round_push_relabel.zig](../../../zig/s/synchronous_round_push_relabel.zig) |
