# GBBS CoSimRank pair similarity

This package isolates one pair-similarity query from GBBS CoSimRank. It starts
two unit page vectors at the selected source vertices, advances each through
the directed graph, and adds the discounted inner product after each round.

## Bounded contract

- Exported symbol: `gbbs_cosimrank_pair_similarity`; ABI:
  `i64_array_bytes_output`.
- Input: `[node_count, edge_count, source_u, source_v, iterations,
  (edge_from, edge_to)...]`.
- Bounds: `1 <= node_count <= 8`, `0 <= edge_count <= 24`, and
  `1 <= iterations <= 4`; exact input length is `5 + 2*edge_count`.
- The graph is a directed simple graph without self-loops. Every nonzero
  outdegree must be 1, 2, or 4. This makes every bounded walk transition
  exactly representable in a common 2^8 fixed-point scale for four rounds.
- The profile fixes the similarity discount to `c=0.5` and runs exactly the
  requested number of rounds with `epsilon=0`. It returns one little-endian
  IEEE-754 binary64 bit pattern. Invalid input returns `-1`; null output or
  capacity below eight returns `-2` without writing.
- The ports use exact integer dyadic arithmetic and form the binary64 bits
  directly. For this bounded profile that produces the same exact value as
  the binary64 recurrence, while avoiding language-specific float bitcasts.

## Source and rights

Source is pinned to
[ParAlg/gbbs commit `dbd1dcad582c0a316c5ba0d5524319d596dd82da`](https://github.com/ParAlg/gbbs/tree/dbd1dcad582c0a316c5ba0d5524319d596dd82da).
The implementation is
[`benchmarks/CoSimRank/CoSimRank.h`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/CoSimRank/CoSimRank.h),
with launcher options in
[`benchmarks/CoSimRank/CoSimRank.cc`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/CoSimRank/CoSimRank.cc).
The bounded profile uses the source's pair initialization, transition, inner
product, and discounted accumulation. It fixes `-u`, `-v`, `-iters`, `-cons`
and disables tolerance-based early termination. GBBS is MIT licensed; the
complete notice is retained in [LICENSE.txt](LICENSE.txt). All ports are
clean-room implementations.

## Ports

| Language | Source |
| --- | --- |
| C | [c/g/gbbs_cosimrank_pair_similarity.c](../../../c/g/gbbs_cosimrank_pair_similarity.c) |
| C3 | [c3/g/gbbs_cosimrank_pair_similarity.c3](../../../c3/g/gbbs_cosimrank_pair_similarity.c3) |
| C++ | [cpp/g/gbbs_cosimrank_pair_similarity.cpp](../../../cpp/g/gbbs_cosimrank_pair_similarity.cpp) |
| Elisa | [elisa/g/gbbs_cosimrank_pair_similarity.elisa](../../../elisa/g/gbbs_cosimrank_pair_similarity.elisa) |
| Nim | [nim/g/gbbs_cosimrank_pair_similarity.nim](../../../nim/g/gbbs_cosimrank_pair_similarity.nim) |
| Odin | [odin/g/gbbs_cosimrank_pair_similarity.odin](../../../odin/g/gbbs_cosimrank_pair_similarity.odin) |
| Rust | [rust/g/gbbs_cosimrank_pair_similarity.rs](../../../rust/g/gbbs_cosimrank_pair_similarity.rs) |
| V | [v/g/gbbs_cosimrank_pair_similarity.v](../../../v/g/gbbs_cosimrank_pair_similarity.v) |
| Zig | [zig/g/gbbs_cosimrank_pair_similarity.zig](../../../zig/g/gbbs_cosimrank_pair_similarity.zig) |

Fixtures are in [workload.json](workload.json). The primary oracle follows the
bounded vector recurrence; the verifier oracle independently evaluates it
with exact rational arithmetic.
