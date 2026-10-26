# Single-buffer packet switching policies

This package runs the chapter's FIFO single-buffer packet policies over a
bounded arrival trace. The policy selector chooses one of the three chapter
variants: `0` Natural Greedy, `1` Preemptive Greedy (PG), or `2` Modified
Preemptive Greedy (MPG). PG and MPG use the chapter's highlighted value
`β=15`. Input packets carry integer values from 1 through 100 and arrive in
nondecreasing slot order. One oldest resident packet is transmitted at the end
of each slot, if the buffer is nonempty.

Natural Greedy accepts a packet if there is room. If full, it compares the new
packet with the minimum-value resident: a strictly higher new value replaces
the oldest minimum-value resident; otherwise the new packet is rejected. For
PG, before the Natural Greedy rule, the earliest FIFO resident with
`β·resident_value <= new_value` is preempted and the new packet is accepted.
For MPG, the earliest resident satisfying both `β·resident_value < new_value`
and “resident value is no greater than the following resident's value” (or it
is last) is preempted. If no preemption candidate exists, PG and MPG use the
Natural Greedy rule. The input tie rule for Natural Greedy drops the new packet
when it ties the minimum; if several existing packets tie for minimum, it
preempts the oldest. This chooses one deterministic behavior from the source's
allowed minimum-value choices.

Input is `[policy, buffer_capacity, beta, slot_count, packet_count,
(arrival_slot, value)...]`. Bounds are capacity 1–4, 1–8 slots, and at most 16
packets. Output is one packet ID per slot, in arrival-index order, or `-1` for
an idle slot. The trace measures the three policies' actual finite-run FIFO
behavior; it does not evaluate their competitive ratios or simulate an
offline optimum.

The primary oracle simulates arrival-time updates and FIFO service. The
independent verifier finds preemption candidates through separate earliest
eligible searches and independently reconstructs the resident trace.

Source: “Packet Switching in Single Buffer,” *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_275`](https://doi.org/10.1007/978-1-4939-2864-4_275).
See [RIGHTS.md](RIGHTS.md) for provenance.

## Workload and ports

The [workload](workload.json) includes Natural Greedy tie behavior, both
preemption rules, maximum arrival bounds, malformed framing, null buffers, and
insufficient capacity.

| Language | Port |
| --- | --- |
| C | [`c/s/packet_switching_single_buffer.c`](../../../c/s/packet_switching_single_buffer.c) |
| C3 | [`c3/s/packet_switching_single_buffer.c3`](../../../c3/s/packet_switching_single_buffer.c3) |
| C++ | [`cpp/s/packet_switching_single_buffer.cpp`](../../../cpp/s/packet_switching_single_buffer.cpp) |
| Elisa | [`elisa/s/packet_switching_single_buffer.elisa`](../../../elisa/s/packet_switching_single_buffer.elisa) |
| Nim | [`nim/s/packet_switching_single_buffer.nim`](../../../nim/s/packet_switching_single_buffer.nim) |
| Odin | [`odin/s/packet_switching_single_buffer.odin`](../../../odin/s/packet_switching_single_buffer.odin) |
| Rust | [`rust/s/packet_switching_single_buffer.rs`](../../../rust/s/packet_switching_single_buffer.rs) |
| V | [`v/s/packet_switching_single_buffer.v`](../../../v/s/packet_switching_single_buffer.v) |
| Zig | [`zig/s/packet_switching_single_buffer.zig`](../../../zig/s/packet_switching_single_buffer.zig) |
