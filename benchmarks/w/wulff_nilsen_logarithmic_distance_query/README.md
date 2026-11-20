# Wulff–Nilsen logarithmic Thorup–Zwick query

This profile implements the (O(\log k))-query refinement from Chapter 568
with the operational recurrence in Sections 2–3 and Figures 2–3 of Wulff–Nilsen.
It fixes `k=16`, the smallest value required by Figure 3's stated precondition.
The current `thorup_zwick_distance_oracle` package fixes `k=2` and uses the
ordinary alternating bunch query; this package precomputes the even-level
distance-gap split tree and follows its binary interval search before running
the Figure 2 query on the final short interval.

## Contract

ABI: `i64_array_bytes_output`, symbol `wulff_nilsen_logarithmic_distance_query`.
Input is
`[n,m,A1,...,A15,(u,v,w)[m],q,(source,target)[q]]`, with `1<=n<=8`,
`0<=m<=n(n-1)/2`, and `0<=q<=32`. The graph is simple, connected when `n>1`,
undirected, and has positive integer edge weights `1..1000`. Edges are encoded
once with `u<v` in strictly increasing lexicographic order. Query endpoints
are zero-based vertex IDs.

`A0=V` and `A16=empty`; the fifteen nonempty masks encode nested sets
`A1 superset A2 superset ... superset A15`. The masks replay one hierarchy
realization, so the profile measures the deterministic query method and makes
no randomized expectation claim. For each level, `p_i(v)` is the nearest
member of `A_i`, with ties resolved by smaller vertex ID; `p_0(v)=v`. The bunch
is the source-defined union of `A_i\A_(i+1)` vertices strictly closer to the
query vertex than its nearest member of `A_(i+1)`. The empty `A16` has infinite
distance, so every `A15` vertex is included.

For every source vertex, preprocessing recursively splits an interval
`[i1,i2]` until `i2-i1<=4` (since `log2(16)=4`). Its split `i` is an even index
in `[i1+2,i2-2]` nearest the interval midpoint, with smaller-index tie break.
Then `j` is the even index in `[i1,i-2]` maximizing
`delta_j(u)=d(u,p_(j+2)(u))-d(u,p_j(u))`; ties use the smaller index. The
intervals recurse as `[i1,j]` and `[i,i2]`. A query tests
`p_j(source) in B(target)` and `p_(j+1)(target) in B(source)`: if both tests
are false it takes the right interval, otherwise the left. At a leaf it runs
Figure 2's alternating `dist_k` scan from the leaf's first level.

Equal source and target endpoints take a profile-level exact-distance fast
path and emit `(0, 0)` without entering the recurrence. Each other query emits
`(estimate, membership_probe_count)`. A probe is one membership lookup in a
bunch: each internal interval node contributes two probes, and each Figure 2
loop iteration contributes one. Both interval tests are evaluated at every
internal node. Output is little-endian signed-i64
`[q, estimate_0, probes_0, ...]`; maximum output is 520 bytes. Maximum valid
input is 166 words, with 167 words accepted by the parser only to reject a
trailing-value frame. Fixed workspace is bounded at 16,384 bytes, including
the 64-bit interval-node storage and staged output. The widest fixed layout is
14,216 bytes before scalar locals: 13,568 bytes for the 64-bit `State`, 128
bytes for hierarchy masks, and 520 bytes for staged output. In that layout,
the interval nodes account for `8 * 31 * 48 = 11,904` bytes. The remaining
2,168 bytes cover locals; tree construction uses at most four recursive frames
and happens before the staged output array is allocated.

Malformed input returns `-1`. Valid input with a null output buffer or too
little capacity returns `-2`; input validation takes precedence, and failures
write no bytes.

## References and scope

Primary operational source: Christian Wulff–Nilsen, “Approximate Distance
Oracles with Improved Query Time,” Sections 2–3, Figures 2–3,
[arXiv:1202.2336](https://arxiv.org/abs/1202.2336). Chapter context:
“Approximate Distance Oracles with Improved Query Time,” *Encyclopedia of
Algorithms*, DOI [10.1007/978-1-4939-2864-4_568](https://doi.org/10.1007/978-1-4939-2864-4_568).
The paper supplies the interval recurrence and branch rule; deterministic
nearest-midpoint selection and smaller-index tie rules pin its implementation
choices for replay. The input masks stand in for the sampled hierarchy.

The primary reference uses Floyd–Warshall and stores each source's split tree.
The independent reference uses repeated Dijkstra and recomputes the split
decision while descending a query. Both references and all ports are clean-room
implementations of the stated operations; no source code or test data is copied.
See [RIGHTS.md](RIGHTS.md) for provenance.

## Package files

- Workload: [workload.json](workload.json)
- Package inventory: [INVENTORY.md](INVENTORY.md)
- Primary reference: [wulff_nilsen_logarithmic_distance_query_oracle.py](../../wulff_nilsen_logarithmic_distance_query_oracle.py)
- Independent reference: [wulff_nilsen_logarithmic_distance_query_verifier_oracle.py](../../wulff_nilsen_logarithmic_distance_query_verifier_oracle.py)

| Language | Port |
|---|---|
| C | `c/w/wulff_nilsen_logarithmic_distance_query.c` |
| C3 | `c3/w/wulff_nilsen_logarithmic_distance_query.c3` |
| C++ | `cpp/w/wulff_nilsen_logarithmic_distance_query.cpp` |
| Elisa | `elisa/w/wulff_nilsen_logarithmic_distance_query.elisa` |
| Mojo | `mojo/w/wulff_nilsen_logarithmic_distance_query.mojo` |
| Nim | `nim/w/wulff_nilsen_logarithmic_distance_query.nim` |
| Odin | `odin/w/wulff_nilsen_logarithmic_distance_query.odin` |
| Rust | `rust/w/wulff_nilsen_logarithmic_distance_query.rs` |
| V | `v/w/wulff_nilsen_logarithmic_distance_query.v` |
| Zig | `zig/w/wulff_nilsen_logarithmic_distance_query.zig` |

The source set is a static draft. No reference, program, test, checker, build,
compiler, or benchmark has been run.
