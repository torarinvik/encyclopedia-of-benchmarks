# Single-Source Fully Dynamic Reachability by Rebuild

This bounded deterministic profile implements the chapter's explicit baseline
for “Single-Source Fully Dynamic Reachability,” *Encyclopedia of Algorithms*,
DOI 10.1007/978-1-4939-2864-4_376: after each edge insertion or deletion, run a
graph traversal from the fixed source and refresh the maintained Boolean
reachability vector; answer subsequent queries from that vector.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n,source,initial_edge_count,(u,v)*,operation_count,(kind,a,b)*]`. The graph
is directed, has 2–8 vertices, at most 16 initial edges, and at most 20
operations. Edge endpoints are zero-based. Operation kind 0 inserts directed
edge `(a,b)`, kind 1 deletes it, and kind 2 queries reachability to vertex
`a`; query records require `b=0`. Insertions of present edges and deletions of
absent edges are idempotent. Initial edge records must be unique.

The output is `[query_count,answer_0,...]`, with answers in operation order
and each answer 1 or 0. The source is reachable from itself by a zero-edge
path. Output uses at most 21 signed 64-bit words (168 bytes). Malformed input
returns `-1`; null or insufficient output returns `-2` without writes.

The chapter's advanced subquadratic method relies on a fully dynamic
all-pairs reachability oracle whose construction is not specified in the
chapter, and its Sankowski extension is randomized with one-sided error. This
package covers the explicit traversal-after-update baseline only; it does not
claim those advanced bounds.

## Files

Nine language ports are under `c/s`, `cpp/s`, `rust/s`, `c3/s`, `nim/s`,
`odin/s`, `elisa/s`, `v/s`, and `zig/s`. The workload and two oracles define
the bounded trace and independent query-time BFS check.

## Source and rights

Camil Demetrescu and Giuseppe F. Italiano, “Single-Source Fully Dynamic
Reachability,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_376`](https://doi.org/10.1007/978-1-4939-2864-4_376).
The chapter describes the traversal-after-update baseline but grants no
source-code license. The ports are clean-room implementations; see
[RIGHTS.md](RIGHTS.md), the [workload](workload.json), [primary oracle](../../single_source_dynamic_reachability_rebuild_oracle.py),
and [independent verifier](../../single_source_dynamic_reachability_rebuild_verifier_oracle.py).
