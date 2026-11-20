# Multi-queue Random Schedule packet switching

This package implements the randomized **Random Schedule** service policy
described in §3.2 of Albers and Jacobs. The switch has a bounded set of equal
unit-value queues. Each admitted arrival contributes a supplied priority to a
fixed-capacity auxiliary queue. When that auxiliary queue is full, its oldest
priority tag is removed before the new unmarked tag is appended. A service
chooses the largest unmarked priority across all auxiliary queues, marks it,
and transmits from that tag's queue. When no unmarked tag remains, it serves
the smallest-index nonempty queue. The source permits arbitrary priority ties;
this profile breaks them by queue index and then oldest tag.

The input frame is `[m, B, T, arrivals[m*T], priorities[m*T]]`, with both
matrices slot-major and queue-major. `m` is 2–4, `B` is 1–4, and `T` is 1–8.
Each arrival entry is 0 or 1. A packet is admitted only when its data queue
has space; an arrival to a full queue is dropped. The priority matrix supplies
one replay word for every queue-slot cell. For an admitted arrival, a word
`r` in `0..2^32-1` denotes `(r+1)/(2^32+1)`, which lies in `(0,1)` as required
by the source. Words for absent or rejected arrivals are ignored. This tape
replaces random draws, so the benchmark is reproducible and makes no claim
about the randomized competitive ratio or probability distribution.

The output is one signed 64-bit little-endian queue index per slot, or `-1`
when every data queue is empty. Malformed input returns `-1`; a null output or
capacity below `8*T` returns `-2`, without writing output. The maximum valid
input is 67 words; the parseable bound is 68 words. Output is at most 64 bytes
and bounded workspace is 512 bytes.

The primary oracle simulates the bounded priority queues and marks selected
tags. The independent reference keeps arrival-tag records with serial ages and
reselects the minimum canonical ordering `(-priority, queue, age)` on every
slot. Both reproduce the same supplied priority tape without a PRNG.

Source: Susanne Albers and Tobias Jacobs, “An Experimental Study of New and
Known Online Packet Buffering Algorithms,” §3.2, DOI
[`10.1007/s00453-008-9230-y`](https://doi.org/10.1007/s00453-008-9230-y),
Random Schedule algorithm; chapter context: Markus Schmidt, “Packet Switching
in Multi-queue Switches,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_274`](https://doi.org/10.1007/978-1-4939-2864-4_274).
The local [`packet_switching_sgr_multi_queue`](../packet_switching_sgr_multi_queue/README.md)
package implements deterministic SGR with a different selection policy; a
work-conserving packet-route trace likewise lacks Random Schedule's priority
tags and marking state.

## Workload and ports

The [workload](workload.json) covers priority ordering, a priority-tag eviction
that creates a later fallback service, priority ties, idle slots, maximum
bounds, malformed frames, null buffers, and insufficient output capacity.

| Language | Port |
| --- | --- |
| C | [`c/p/packet_switching_random_schedule.c`](../../../c/p/packet_switching_random_schedule.c) |
| C3 | [`c3/p/packet_switching_random_schedule.c3`](../../../c3/p/packet_switching_random_schedule.c3) |
| C++ | [`cpp/p/packet_switching_random_schedule.cpp`](../../../cpp/p/packet_switching_random_schedule.cpp) |
| Elisa | [`elisa/p/packet_switching_random_schedule.elisa`](../../../elisa/p/packet_switching_random_schedule.elisa) |
| Mojo | [`mojo/p/packet_switching_random_schedule.mojo`](../../../mojo/p/packet_switching_random_schedule.mojo) |
| Nim | [`nim/p/packet_switching_random_schedule.nim`](../../../nim/p/packet_switching_random_schedule.nim) |
| Odin | [`odin/p/packet_switching_random_schedule.odin`](../../../odin/p/packet_switching_random_schedule.odin) |
| Rust | [`rust/p/packet_switching_random_schedule.rs`](../../../rust/p/packet_switching_random_schedule.rs) |
| V | [`v/p/packet_switching_random_schedule.v`](../../../v/p/packet_switching_random_schedule.v) |
| Zig | [`zig/p/packet_switching_random_schedule.zig`](../../../zig/p/packet_switching_random_schedule.zig) |

See [RIGHTS.md](RIGHTS.md) for provenance and rights notes and
[INVENTORY.md](INVENTORY.md) for the static source inventory. The
`i64_array_bytes_output` runner and verifier registration is integrated.
