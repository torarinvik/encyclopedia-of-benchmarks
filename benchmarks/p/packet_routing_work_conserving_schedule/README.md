# Work-conserving packet routing schedule

This profile measures the scheduling phase for supplied simple packet routes.
Each input link is an undirected physical resource with capacity one packet per
synchronous time step, shared by transmissions in either direction. At each
step, every link with waiting packets transmits one packet; ties select the
lowest packet ID. Choices are made from the beginning-of-step queues and all
selected packets advance simultaneously by one route edge. The chapter states
that any work-conserving schedule completes within `c*d` steps, where `c` is
maximum link congestion and `d` is maximum route dilation.

Input is signed i64 words:

```text
[n,m,p, (endpoint_a,endpoint_b)*m, (start_vertex,route_length,link_id...)*p]
```

Vertices, link IDs, and packet IDs are zero-based. Links are undirected and
unique by endpoint pair. Each route is a contiguous simple path in the link
list; the route's start vertex is supplied and direction is inferred from each
link's endpoints. Bounds are `2<=n<=8`, `1<=m<=12`, `1<=p<=8`, route length at
most `n-1`, and input length at most 99 words. Routes are assumed preselected;
the profile does not optimize them.

Output is little-endian signed i64:

```text
[makespan,transmission_count, (time,link_id,packet_id)*transmission_count]
```

Records are ordered by time and then link ID. Maximum output is 1360 bytes and
fixed workspace is 4096 bytes. Malformed input returns `-1`; null output or
insufficient capacity returns `-2` without writing. The randomized LMR delay
scheduler, conditional-probability derandomization, path selection, and
approximation guarantees are excluded.

Source: Lenore J. Cowen, “Packet Routing,” *Encyclopedia of Algorithms*, DOI
`10.1007/978-1-4939-2864-4_273`, EPUB `OEBPS/AChap273.html`, “Problem Definition”
and “Key Results.” The chapter says one packet may cross each individual link
per timestep and gives the work-conserving `c*d` bound, but no source-code
license. These ports are clean-room implementations with a deterministic
packet-ID tie refinement.

| Language | Port |
|---|---|
| C | `c/p/packet_routing_work_conserving_schedule.c` |
| C++ | `cpp/p/packet_routing_work_conserving_schedule.cpp` |
| Rust | `rust/p/packet_routing_work_conserving_schedule.rs` |
| Nim | `nim/p/packet_routing_work_conserving_schedule.nim` |
| Odin | `odin/p/packet_routing_work_conserving_schedule.odin` |
| Zig | `zig/p/packet_routing_work_conserving_schedule.zig` |
| V | `v/p/packet_routing_work_conserving_schedule.v` |
| C3 | `c3/p/packet_routing_work_conserving_schedule.c3` |
| Elisa | `elisa/p/packet_routing_work_conserving_schedule.elisa` |
