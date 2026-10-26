# Streaming triangle estimator

This package implements a bounded, deterministic replay of the chapter's
full `Streaming-Triangles` update procedure: the edge reservoir, sampled wedge
reservoir, future-closure flags, and running transitivity/triangle estimates.
The random outcomes are supplied as an explicit tape so each call is
reproducible. The profile does not make a statistical accuracy claim for one
chosen tape.

## Contract

The ABI is `i64_array_bytes_output`, symbol `streaming_triangles`. Input is
`[n,m,se,sw,edges[2*m],tape]`. The tape has `m` records of
`[edge_draw,edge_slot,(wedge_draw,wedge_pick)[sw]]`.
`n<=8`, `m<=28`, `se` is 2..4, and `sw` is 1..4. At time `t` (one-based),
`edge_draw` is uniform over the integer range `[0,t^se)` and an edge-reservoir
update occurs when it is below `t^se-(t-1)^se`, exactly representing the
chapter's probability `1-(1-1/t)^se`. On update, `edge_slot` selects the
replaced edge slot. The resulting `N_t` is formed from the incoming edge and
the other currently resident edge slots; the evicted edge is excluded. Each wedge slot
uses `wedge_draw` uniform in `[0,tot_wedges)` and replaces when it is less
than `new_wedges`; `wedge_pick` selects a uniform new wedge. When a choice is
unused, its tape field must be zero.

Before updating the edge reservoir, the incoming edge marks any sampled wedge
with matching outer endpoints as closed. Wedge closure is retained until that
wedge slot is replaced. After each edge, the output triple is
`[tot_wedges,kappa_q,triangles_q]`, where `kappa_q=floor(3*rho*1,000,000)` and
`triangles_q=floor(rho*t^2*tot_wedges*1,000,000/(se*(se-1)))`; `rho` is the
closed fraction of the `sw` wedge slots. `tot_wedges` is the current wedge
count in the edge-reservoir subgraph: replacing a sampled edge removes its old
incident wedges and inserts `N_t`. This is the chapter's running
estimator formula with integer floor serialization. The result is three
little-endian signed 64-bit values per prefix. Malformed input returns `-1`
before output checks; null output or capacity below `24*m` bytes returns
`-2` without writes. Maximum input is 340 words and maximum output is 672
bytes.

The package preserves a limitation the paper explicitly notes in §6.1: when
an edge-reservoir replacement removes a wedge from the current `W_t`, an old
sampled wedge can remain in the wedge reservoir until that slot is replaced.
The heuristic treats that old sample as if it were still in `W_t`; the paper
acknowledges this is technically incorrect. Accordingly, `tot_wedges` and the
new-wedge replacement probability use the current edge-reservoir subgraph,
while a retained wedge sample may describe an earlier subgraph. The bounded
profile reproduces that sampling behavior and does not claim to repair the
paper's stated limitation.

## Source and scope

Based on Madhav Jha, “Counting Triangles in Graph Streams,” *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_705`](https://doi.org/10.1007/978-1-4939-2864-4_705),
especially the `Streaming-Triangles` and `Update` procedures. The package
exposes one fixed-size profile with explicit random draws; one output trace
does not demonstrate the source's expected accuracy bounds. See
[`RIGHTS.md`](RIGHTS.md).

The earlier [`counting_triangles_stream_reservoir`](../counting_triangles_stream_reservoir/README.md)
package isolates the uniform edge-reservoir primitive. This package includes
that mechanism and the chapter's additional wedge and estimator state.

Fixtures are in [`workload.json`](workload.json); oracle models are
[`streaming_triangles_oracle.py`](../../streaming_triangles_oracle.py) and
[`streaming_triangles_verifier_oracle.py`](../../streaming_triangles_verifier_oracle.py).
