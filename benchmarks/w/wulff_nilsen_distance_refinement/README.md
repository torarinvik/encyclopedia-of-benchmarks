# Wulff–Nilsen constant-query distance refinement

This profile ports the generic refinement query in Figure 4 of Wulff–Nilsen's
paper, cross-listed as Chapter 568 of the *Encyclopedia of Algorithms*. It is
the fixed-parameter `refine_dist` kernel, not the complete Mendel–Naor plus
Wulff–Nilsen oracle: the caller supplies one hierarchy realization and one
valid coarse distance estimate. The local `thorup_zwick_distance_oracle`
benchmarks the ordinary `k=2` alternating query; the local
`wulff_nilsen_logarithmic_distance_query` benchmarks the separate `k=16`
interval-search query. This profile measures the constant-query refinement
recurrence with `k=4`, `epsilon=1/2`, and `alpha=192`.

## Contract

- ABI: `i64_array_scalar`, exported symbol `wulff_nilsen_distance_refinement`.
- Input: `[n,m,A1,A2,A3,(u,v,w)*m,source,target,d_tilde]`.
- `2<=n<=8`; the undirected graph is simple, connected, has `0<=m<=28` edges,
  and uses positive weights `w=S*b`, where `S=2*3^16=86,093,442` and
  `1<=b<=100`. Edges have `u<v` and appear in strictly increasing
  lexicographic order.
- `A0=V`, `A1` through `A3` are nonempty nested vertex sets encoded as masks,
  and `A4=empty`. The masks replay a supplied hierarchy realization; this
  profile makes no randomized expectation claim. For each vertex `x`, `p0(x)=x`
  and `pi(x)` is the nearest member of `Ai`, breaking equal-distance ties by
  lower vertex ID. `B_x` is the standard Thorup–Zwick bunch: the union over
  levels `i=0..3` of vertices in `Ai\A(i+1)` closer to `x` than its nearest
  member of `A(i+1)`; the empty `A4` has infinite distance.
- The query endpoints must differ. `d_tilde` is positive, divisible by `S`,
  and must satisfy `d_G(source,target) <= d_tilde <= 768*d_G(source,target)`.
  The factor 768 is `alpha*k` for `alpha=192`, `k=4`. The paper obtains
  `alpha=(1+epsilon)*128=192` from the Mendel–Naor estimate; this package
  validates the corresponding estimate promise but does not construct that
  oracle.
- `even_x(d)` is the largest even `i` in `{0,2}` with
  `d_G(x,pi(x))<=d`. Figure 4 first tests `refine_further`; if false, it returns
  `d_tilde`. Otherwise it repeatedly replaces `d` by `2d/3` while the
  predicate remains true and the source loop index is at most
  `ceil(log(2*alpha)/log(1+epsilon))=15`, allowing 16 reductions. The final
  `even_x(3d/2)` level selects the paper's maximum-`delta_j` even index and
  four ordered bunch tests. At `k=4`, the only possible `j` is 0.
- All valid weights and estimates are multiples of `S`, so every one of the
  16 `2/3` reductions and each `3/2` threshold remains integral. The maximum
  valid frame is 92 i64 words; the parser accepts at most 93 words so a
  trailing-value probe is representable. Invalid or null input returns `-1`.
- The output is the refined distance as one signed i64 scalar. Under the
  source guarantee it is at least the true distance and at most 11 times that
  distance (`2*(1+epsilon)*k-1=11`). With `n<=8` and base edge weight at most
  100, the maximum simple-path distance is 60,265,409,400 and the corresponding
  11-stretch ceiling is 662,919,503,400, well inside signed i64. The declared
  workspace cap is 8,192 bytes; the fixed distance, nearest-sample, bunch,
  hierarchy, and temporary state arrays use under 2 KiB, leaving room for language
  runtime locals.

The primary reference uses Floyd–Warshall. The independent reference
enumerates bounded simple paths to obtain distances and evaluates bunch
membership on demand rather than materializing the primary bunch table.
Complexity is `O(n^3 + 16)` for the primary query profile; the independent
distance oracle enumerates at most the simple paths of an 8-vertex graph.

## Sources and provenance

Operational source: Christian Wulff–Nilsen, “Approximate Distance Oracles with
Improved Query Time,” §4.1 and Figure 4, [arXiv:1202.2336](https://arxiv.org/abs/1202.2336),
[DOI 10.1137/1.9781611973105.39](https://doi.org/10.1137/1.9781611973105.39).
Book crosswalk: “Approximate Distance Oracles with Improved Query Time,”
*Encyclopedia of Algorithms*, [DOI 10.1007/978-1-4939-2864-4_568](https://doi.org/10.1007/978-1-4939-2864-4_568).
The paper defines the recurrence, stopping condition, bunch tests, and stretch
bound. This clean-room profile supplies deterministic lower-ID nearest-sample
ties and fixed hierarchy/estimate inputs. No paper code, text, examples, or
test fixtures are copied. See [RIGHTS.md](RIGHTS.md).

## Package files

- Primary reference: `benchmarks/wulff_nilsen_distance_refinement_oracle.py`
- Independent reference: `benchmarks/wulff_nilsen_distance_refinement_independent_oracle.py`
- Workload: [workload.json](workload.json)
- Static package inventory: [INVENTORY.md](INVENTORY.md), [inventory.json](inventory.json)
- Static helpers: `check_inventory.py`, `verify_workload.py`

| Language | Port |
|---|---|
| C | `c/w/wulff_nilsen_distance_refinement.c` |
| C3 | `c3/w/wulff_nilsen_distance_refinement.c3` |
| C++ | `cpp/w/wulff_nilsen_distance_refinement.cpp` |
| Elisa | `elisa/w/wulff_nilsen_distance_refinement.elisa` |
| Mojo | `mojo/w/wulff_nilsen_distance_refinement.mojo` |
| Nim | `nim/w/wulff_nilsen_distance_refinement.nim` |
| Odin | `odin/w/wulff_nilsen_distance_refinement.odin` |
| Rust | `rust/w/wulff_nilsen_distance_refinement.rs` |
| V | `v/w/wulff_nilsen_distance_refinement.v` |
| Zig | `zig/w/wulff_nilsen_distance_refinement.zig` |

Shared `i64_array_scalar` runner/verifier, catalog, and Chapter 568 crosswalk
registration are integrated.
