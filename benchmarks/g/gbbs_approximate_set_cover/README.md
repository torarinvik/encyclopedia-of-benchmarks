# GBBS approximate set cover

This is a bounded deterministic profile of GBBS's MANISBPT11 approximate
set-cover kernel. It preserves the source's epsilon=0.01 logarithmic degree
buckets, highest-bucket processing, random-priority element acquisition,
winner-count threshold and rebucketing behavior. The upstream parallel code
uses a random permutation per bucket round; this profile replaces that source
randomness with a deterministic cyclic priority order (round `r` starts at set
ID `r mod set_count`) so every port has one reproducible result.

## Contract

- Symbol: `gbbs_approximate_set_cover`; ABI: `i64_array_bytes_output`.
- Input: `[vertex_count, neighbor_mask_0, ...]`, a simple undirected graph
  encoded as symmetric adjacency bitmasks. As in the pinned kernel, each graph
  vertex is a candidate set containing its neighbors, and graph vertices are
  the universe elements.
- Bounds: 1–8 vertices; exact length `1 + vertex_count`. Self-loop bits,
  asymmetric masks, and out-of-range bits are invalid. Isolated elements may
  remain uncovered because a neighborhood set does not contain its own vertex.
- For at most eight elements, the source bucket thresholds coincide with the
  integer degree. The algorithm retains source bucket state between rounds,
  processes the highest stored bucket, recomputes only that bucket's uncovered
  degrees, assigns each uncovered element to its highest-priority eligible
  adjacent set, adds
  sets that win all their remaining elements, marks their elements covered,
  and repeats. Priority ties follow the documented cyclic order.
- Output is two little-endian signed-i64 values: selected-vertex-set bitmask,
  then remaining-uncovered-vertex bitmask. Success writes 16 bytes; malformed
  input returns `-1`; null output or capacity below 16 returns `-2` without
  writing. A universe with no incident sets is reported in the second mask.
- Graph parsing, GBBS scheduling/bucketing data structures, timing, CLI output,
  and the source's nondeterministic random-number stream are outside this
  bounded profile.

## Source and rights

Pinned source: [`ApproximateSetCover.h::SetCover`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/ApproximateSetCover/MANISBPT11/ApproximateSetCover.h)
and [`ApproximateSetCover.cc::SetCover_runner`](https://github.com/ParAlg/gbbs/blob/dbd1dcad582c0a316c5ba0d5524319d596dd82da/benchmarks/ApproximateSetCover/MANISBPT11/ApproximateSetCover.cc),
GBBS commit `dbd1dcad582c0a316c5ba0d5524319d596dd82da`. The local
`greedy_min_vertex_cover` package is related but distinct: it solves a graph
vertex-cover problem using maximum-current-degree selection, while this
profile operates on set-to-element incidence masks and the source's bucketed
priority acquisition procedure.

The source repository is MIT licensed. Full notice: [`LICENSE.txt`](LICENSE.txt).
All language ports are clean-room implementations.

## Package artifacts

- Workload: [`workload.json`](workload.json)
- Primary oracle: [`gbbs_approximate_set_cover_oracle.py`](../../gbbs_approximate_set_cover_oracle.py)
- Independent verifier model: [`gbbs_approximate_set_cover_verifier_oracle.py`](../../gbbs_approximate_set_cover_verifier_oracle.py)
