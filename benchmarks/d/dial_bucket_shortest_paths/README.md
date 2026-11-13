# Dial bucket shortest paths

Compute shortest-path distances from one source in a directed graph with
nonnegative integer edge weights bounded by eight. The primary method is Dial's
cyclic exact-distance bucket queue; the independent oracle uses Floyd–Warshall.

## Contract

The exported symbol is
`dial_bucket_shortest_paths(input, length, output, capacity) -> i64` under the
`i64_array_bytes_output` ABI. Input is
`[N,M,source,(u,v,weight)*M]`, with `1<=N<=16`, `0<=M<=64`, vertex IDs
`0..N-1`, and `0<=weight<=8`. Edges are directed; self-loops, parallel
edges, and zero-weight edges are valid. The source must satisfy
`0<=source<N`. The exact frame length is `3+3*M`; the maximum valid and
parseable lengths are 195 and 196 signed-i64 words. The maximum finite
shortest-path distance is `(N-1)*8 = 120`.

On success, output one signed little-endian i64 distance per vertex, in vertex
order. Unreachable vertices are `-1`; the return value is `8*N`. Invalid or
malformed input returns `-1`. A null output pointer or capacity below `8*N`
returns `-2` without modifying output. Workspace is 4,096 bytes.

## Algorithm

Use a ring of exactly nine buckets, indexed by `distance mod 9`. The queue
stores vertex/distance records. Process current distances in increasing order,
draining that exact-distance bucket completely; this includes zero-weight
relaxations that append to the bucket being drained. Skip a record if its
distance is no longer the vertex's best known distance or the vertex was
settled. Since edge weights are at most eight, records that become eligible
from a settled distance cannot alias a future distance in the same ring slot
before that slot's current distance has been drained. There are at most `M+1`
queue records because each edge is examined once from its settled origin.
The running time is `O(M+N*C)` with `C=8`, and auxiliary space is
`O(N+M+C)`.

The independent Floyd–Warshall oracle performs all-pairs relaxation and reads
the selected source row, rather than using a bucket queue.

Dijkstra's general priority frontier and delta-stepping's light-edge closure
have different scheduling rules. This package covers exact integer distance
buckets for the small bounded weight domain. The zero-one BFS package is
specialized to weights 0 and 1.

See [workload.json](workload.json), [primary_oracle.py](primary_oracle.py),
[independent_oracle.py](independent_oracle.py), [RIGHTS.md](RIGHTS.md), and
[check_inventory.py](check_inventory.py).

## Implementations

| Language | File |
| --- | --- |
| C | [../../../c/d/dial_bucket_shortest_paths.c](../../../c/d/dial_bucket_shortest_paths.c) |
| C3 | [../../../c3/d/dial_bucket_shortest_paths.c3](../../../c3/d/dial_bucket_shortest_paths.c3) |
| C++ | [../../../cpp/d/dial_bucket_shortest_paths.cpp](../../../cpp/d/dial_bucket_shortest_paths.cpp) |
| Elisa | [../../../elisa/d/dial_bucket_shortest_paths.elisa](../../../elisa/d/dial_bucket_shortest_paths.elisa) |
| Mojo | [../../../mojo/d/dial_bucket_shortest_paths.mojo](../../../mojo/d/dial_bucket_shortest_paths.mojo) |
| Nim | [../../../nim/d/dial_bucket_shortest_paths.nim](../../../nim/d/dial_bucket_shortest_paths.nim) |
| Odin | [../../../odin/d/dial_bucket_shortest_paths.odin](../../../odin/d/dial_bucket_shortest_paths.odin) |
| Rust | [../../../rust/d/dial_bucket_shortest_paths.rs](../../../rust/d/dial_bucket_shortest_paths.rs) |
| V | [../../../v/d/dial_bucket_shortest_paths.v](../../../v/d/dial_bucket_shortest_paths.v) |
| Zig | [../../../zig/d/dial_bucket_shortest_paths.zig](../../../zig/d/dial_bucket_shortest_paths.zig) |

