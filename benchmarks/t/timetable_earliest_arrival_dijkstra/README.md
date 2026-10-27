# Timetable Earliest-Arrival Dijkstra

This bounded profile models stations as vertices and scheduled direct train
connections as directed arcs. It follows the time-dependent shortest-path
model described in Riko Jacob's “Shortest Paths Approaches for Timetable
Information,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_371`](https://doi.org/10.1007/978-1-4939-2864-4_371).
The query asks for the earliest arrival at one destination from a supplied
source and start time. Transfer time is zero, as in the chapter's simplifying
model.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[n,arc_count,source,target,start_time, arc...]`. Each directed arc record is
`[u,v,trip_count,(departure,arrival)*]`. The graph has 2–8 stations and at most
12 arcs, with no self-loops or duplicate ordered pairs. An arc has 1–4 trips;
departures strictly increase and arrivals are nondecreasing, so each discrete
edge-traversal function is FIFO. Every arrival is later than its departure.
The start time and departures are in `[0,1000]`; arrivals are at most 2000.
The largest valid input is 137 signed 64-bit values; the parser accepts at
most 138 values before requiring an exact parse.

When a passenger reaches station `u` at time `t`, an outgoing arc can be used
on its first listed trip whose departure is at least `t`. The package applies
the modified Dijkstra recurrence to these FIFO edge-arrival functions. It
settles equal arrival times by smaller station ID. If multiple predecessors
give a station the same earliest arrival, it retains the smaller predecessor
ID. This local rule, together with the recursive predecessor choices,
determines the returned path. A reachable result is
`[1,arrival,path_length,vertex_0,...,vertex_last]`; an unreachable result is
`[0,-1,0]`. A source-equals-target query returns the zero-edge path containing
only the source. The maximum result is 88 bytes. Malformed input returns
`-1`; a null output or insufficient capacity returns `-2` without writes.

The primary oracle uses the same time-dependent Dijkstra recurrence. The
independent verifier enumerates simple station paths to determine earliest
arrival times, then reconstructs the specified smallest-predecessor path from
those times. Both check the exact output bytes.

This profile covers the chapter's simplest earliest-arrival model. It does
not model positive transfer times, fares, transfer limits, multi-criteria
Pareto itineraries, time-expanded event graphs, or real-time delays and
cancellations. Its edge function is represented by a small explicit list of
departure/arrival events rather than a compressed timetable index.

## Workload and ports

The [workload](workload.json) includes waiting for a later connection, an
equal-arrival path tie, an unreachable destination, source-equals-target,
maximum station/arc/output bounds, non-FIFO malformed input, capacity failure,
and null buffers.

| Language | Port |
| --- | --- |
| C | [`c/t/timetable_earliest_arrival_dijkstra.c`](../../../c/t/timetable_earliest_arrival_dijkstra.c) |
| C3 | [`c3/t/timetable_earliest_arrival_dijkstra.c3`](../../../c3/t/timetable_earliest_arrival_dijkstra.c3) |
| C++ | [`cpp/t/timetable_earliest_arrival_dijkstra.cpp`](../../../cpp/t/timetable_earliest_arrival_dijkstra.cpp) |
| Elisa | [`elisa/t/timetable_earliest_arrival_dijkstra.elisa`](../../../elisa/t/timetable_earliest_arrival_dijkstra.elisa) |
| Nim | [`nim/t/timetable_earliest_arrival_dijkstra.nim`](../../../nim/t/timetable_earliest_arrival_dijkstra.nim) |
| Odin | [`odin/t/timetable_earliest_arrival_dijkstra.odin`](../../../odin/t/timetable_earliest_arrival_dijkstra.odin) |
| Rust | [`rust/t/timetable_earliest_arrival_dijkstra.rs`](../../../rust/t/timetable_earliest_arrival_dijkstra.rs) |
| V | [`v/t/timetable_earliest_arrival_dijkstra.v`](../../../v/t/timetable_earliest_arrival_dijkstra.v) |
| Zig | [`zig/t/timetable_earliest_arrival_dijkstra.zig`](../../../zig/t/timetable_earliest_arrival_dijkstra.zig) |

The [primary oracle](../../timetable_earliest_arrival_dijkstra_oracle.py),
[independent verifier](../../timetable_earliest_arrival_dijkstra_verifier_oracle.py),
and [rights note](RIGHTS.md) document the profile's provenance and checks.
