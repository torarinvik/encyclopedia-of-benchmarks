# GPSR Perimeter-Recovery Trace

This benchmark isolates the perimeter-recovery phase of Greedy Perimeter
Stateless Routing (GPSR). It consumes a supplied planar straight-line graph;
it does not build a Gabriel/RNG subgraph, run radio simulation, or benchmark
the preceding greedy phase. The operational source is Karp and Kung,
“GPSR: Greedy Perimeter Stateless Routing for Wireless Networks,” MobiCom
2000, §§2.2 and 2.4, DOI [10.1145/345910.345953](https://doi.org/10.1145/345910.345953).
The bounded chapter crosswalk is *Encyclopedia of Algorithms*, “Geographic
Routing,” Chapter 352, DOI
[10.1007/978-1-4939-2864-4_352](https://doi.org/10.1007/978-1-4939-2864-4_352).
This is distinct from `geometric_greedy_compass_routing`, which selects only
Greedy/Compass neighbors and has no planar rotations, face transitions,
`Lp`/`Lf` state, or perimeter-cycle trace.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n,m,source,target,x[n],y[n],(u,v)[m]]`. Coordinates and IDs are signed i64
words; coordinates lie in `[-16,16]`. The graph has 3–8 vertices and
`n-1 <= m <= min(18,3n-6)` edges, with zero-based endpoints. Each edge has `u<v`,
and edge pairs are strictly lexicographically increasing. The edge list is a
simple, connected planar straight-line embedding. Vertices have distinct
coordinates, no three vertices are collinear, and nonincident edges do not
intersect. These checks rule out angular ties, line-through-vertex events,
overlapping edges, and crossing-embedding ambiguity. The source is a local
maximum relative to the target: no adjacent vertex is strictly closer in
squared Euclidean distance. `source != target`.
Coordinate differences are at most 32; orientation/cross products are at most
2,048 in magnitude, squared distances at most 2,048, and rational-progress
cross-products at most 2,048², all within signed i64.

The maximum valid frame is 56 words; the parser accepts at most 57 words so a
single trailing-word malformed case is representable. At a vertex, incident
neighbors are ordered counterclockwise by exact integer orientation. The
initial edge is the first edge strictly counterclockwise from the source to
target ray. Later edges follow the paper's right-hand rule: from the incoming
edge, choose the next incident edge counterclockwise. When a candidate edge
properly crosses the fixed segment `Lp→target` at parameter `t` with `t > Lf`,
record `(path_index, canonical_edge_id, t_numerator, t_denominator)`, set `Lf`
to that reduced rational parameter, and advance to the next counterclockwise
edge at the same vertex. Continue this face-change scan until the candidate
does not cross closer to the target. This encodes the paper's `FACE-CHANGE`
rule and makes the geometric progress test explicit; the segment starts at
`Lp`, the perimeter-entry/source location.

The packet returns to greedy mode at the first current vertex whose squared
distance to the target is strictly less than the source's distance. The
profile ends there and records status 1; status 2 means the target itself was
reached before that check, and status 0 means the first directed edge of a
face was encountered again (packet drop). `e0` is initialized to the first
selected directed edge and reset to the selected edge after each face change.
The fixed route bound is `2m` directed hops, following the paper's no-repeat
directed-link property; the cap also guards malformed state transitions.

Output is a variable-length little-endian signed-i64 record:
`[status, hop_count, vertex_ids[hop_count+1], crossing_count,
(path_index,edge_id,t_num,t_den)*crossing_count]`. Crossing parameters are
reduced, positive-denominator fractions on `Lp→target`; `path_index` names the
current route vertex from which the skipped crossing edge was considered.
Strictly increasing `Lf` means at most one recorded event per geometric edge,
so there are at most 18 events. With at most 37 route vertices, the maximum is
112 words / 896 bytes. Workspace is capped at 8,192 bytes for bounded parsing,
rotations, geometry, route/event state, and byte serialization.

The fixed payload accounting is 128 bytes of coordinates, 288 bytes of edge
endpoints, 1,024 bytes for adjacency plus rotations, 64 bytes of degrees,
72 bytes of queue/visited state, 296 bytes of route IDs, 576 bytes of crossing
records, and 896 bytes of staged output. This is 3,344 bytes before scalar locals and
container overhead. The 8,192-byte cap includes input staging and conservative
capacity rounding for the C++/Rust bounded vectors.

Invalid input returns `-1`; null output or capacity below 896 bytes returns
`-2` without writing. Both references implement the same replay contract. The
primary stores each vertex's counterclockwise rotation once; the independent
reference recomputes rotations on demand and uses exact rational intersection
parameters. Neither copies source code or source test vectors.

## Files

The ten ports are in `c/g`, `c3/g`, `cpp/g`, `elisa/g`, `mojo/g`, `nim/g`,
`odin/g`, `rust/g`, `v/g`, and `zig/g`. `primary_oracle.py`,
`independent_oracle.py`, and `workload.json` define the reference behavior and
bounded fixtures. Package inventory helpers are source-only metadata; they
have not been executed.
