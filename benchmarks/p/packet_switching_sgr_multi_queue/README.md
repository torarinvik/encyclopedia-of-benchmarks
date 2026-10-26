# Multi-queue SGR packet switching

This package implements the chapter's deterministic SGR (Semi-Greedy) policy
for the unit-value multi-queue switch. The bounded workload supplies an arrival
count for each queue at each slot. Each queue has capacity `B`; when a batch
overflows it, excess unit-value packets are discarded. A slot admits arrivals
before choosing a queue for transmission.

The policy applies its rules in order. If any current queue load is greater
than `floor(B/2)`, it serves a queue with maximum current load. Otherwise, if a
nonempty queue has never reached load `B` in the current busy period, it serves
the maximum-load queue among those queues. If that set is empty, it serves a
maximum-load queue overall. Ties use the smallest queue index. Historical
maximum loads include the post-arrival state at the current slot and reset to
zero when the switch becomes empty. If all queues are empty, the slot records
`-1` and no packet is transmitted.

Input is `[queue_count, B, slot_count, arrivals_by_slot_major_queue]`, with 2–4
queues, `B` from 1 through 4, 1–8 slots, and each per-queue arrival count from
0 through `B`. The output is one signed 64-bit little-endian queue index per
slot, or `-1` for an idle slot. This is the chapter's unit-value case; it does
not model packet priorities, the general-valued policy, SGR competitive-ratio
analysis, or the randomized RS algorithm.

The primary oracle directly simulates the slot transitions. The independent
verifier reconstructs the candidate set from active queues, high-water marks,
and the threshold, then selects by a sorted priority order.

Source: Markus Schmidt, “Packet Switching in Multi-queue Switches,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_274`](https://doi.org/10.1007/978-1-4939-2864-4_274).
See [RIGHTS.md](RIGHTS.md) for provenance.

## Workload and ports

The [workload](workload.json) covers the SGR rule transitions, historical-load
fallback, full queue/slot bounds, malformed arrival framing, null buffers, and
insufficient output capacity.

| Language | Port |
| --- | --- |
| C | [`c/p/packet_switching_sgr_multi_queue.c`](../../../c/p/packet_switching_sgr_multi_queue.c) |
| C3 | [`c3/p/packet_switching_sgr_multi_queue.c3`](../../../c3/p/packet_switching_sgr_multi_queue.c3) |
| C++ | [`cpp/p/packet_switching_sgr_multi_queue.cpp`](../../../cpp/p/packet_switching_sgr_multi_queue.cpp) |
| Elisa | [`elisa/p/packet_switching_sgr_multi_queue.elisa`](../../../elisa/p/packet_switching_sgr_multi_queue.elisa) |
| Nim | [`nim/p/packet_switching_sgr_multi_queue.nim`](../../../nim/p/packet_switching_sgr_multi_queue.nim) |
| Odin | [`odin/p/packet_switching_sgr_multi_queue.odin`](../../../odin/p/packet_switching_sgr_multi_queue.odin) |
| Rust | [`rust/p/packet_switching_sgr_multi_queue.rs`](../../../rust/p/packet_switching_sgr_multi_queue.rs) |
| V | [`v/p/packet_switching_sgr_multi_queue.v`](../../../v/p/packet_switching_sgr_multi_queue.v) |
| Zig | [`zig/p/packet_switching_sgr_multi_queue.zig`](../../../zig/p/packet_switching_sgr_multi_queue.zig) |
