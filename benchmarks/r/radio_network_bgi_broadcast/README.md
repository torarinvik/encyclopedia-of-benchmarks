# BGI radio-network broadcast

This bounded profile replays the complete repeated `Broadcast` schedule in
Bar-Yehuda, Goldreich, and Itai's Chapter 322 entry. It extends the local
[`radio_network_decay_phase`](../d/radio_network_decay_phase/README.md), which
models one synchronized `Decay(k,m)` call without the per-node repeated
schedule.

The input is `[n,source,Delta,adjacency_mask[n],coin_bits[n*t*k]]`. It accepts
`2<=n<=8`, `0<=source<n`, and a supplied upper degree bound `2<=Delta<=8` that
must be at least the graph's maximum degree. The graph is simple, undirected,
and encoded by symmetric vertex-index masks. This profile fixes `N=n` and
`epsilon=1/2`, so

```text
k = 2 * ceil(log2(Delta))
t = ceil(log2(N / epsilon)) = ceil(log2(2*n))
```

All logarithms are base two. The frame has exactly `3+n+n*t*k` signed i64
words, at most 203 words. The coin tape is node-major, then local Decay-call
number, then slot: bit `((v*t + call)*k + slot)` is consumed after node `v`
transmits in that slot. A zero stops the node's current call after its
transmission; a one lets it continue, except that every call ends after its
`k`th send. The bit after the kth send does not affect control flow, but all
tape bits are required and validated.

The source's initial message is its first send in slot 0 and also the first
send of its first Decay call. It starts at the global boundary at time 0. A
vertex first informed in zero-based slot `s` cannot transmit in that slot; its
first eligible send is the smallest slot `u>s` for which `u mod k == 0`.
Within each `k`-slot interval, all informed nodes whose call count is below `t`
run one Decay call together. Nodes learned during an interval join at the next
boundary. A receiver learns the message iff exactly one neighbor transmits in
that slot. There is no collision detection: zero senders and multiple senders
both deliver nothing. This package specifies a deterministic replay of a
supplied tape; it does not generate randomness or claim the paper's
probabilistic success/time bound.

The Chapter 322 PDF appears to print an extra leading factor of two in its
`t` formula. This profile follows §2.2 of the original 1992 paper, where
`t=ceil(log2(N/epsilon))`.

The output is `[n,completed_decay_phases,total_transmissions,first_informed_slot[0..n-1]]`
as little-endian signed i64 values. The source's first slot is 0; an
unreachable vertex has first slot -1. Output length is exactly `8*(n+3)` bytes
and at most 88 bytes. Malformed input returns -1. A null output or insufficient
capacity returns -2 without writing. Fixed implementation workspace is capped
at 2,048 bytes.

The primary reference directly simulates active senders and scans their
neighbor lists. The independent reference advances sender and receiver
bitmasks through the same global intervals. Work is O(n²*t*k) time and O(n)
state. The package does not measure an actual distributed runtime.

| Language | Port |
|---|---|
| C | `c/r/radio_network_bgi_broadcast.c` |
| C3 | `c3/r/radio_network_bgi_broadcast.c3` |
| C++ | `cpp/r/radio_network_bgi_broadcast.cpp` |
| Elisa | `elisa/r/radio_network_bgi_broadcast.elisa` |
| Mojo | `mojo/r/radio_network_bgi_broadcast.mojo` |
| Nim | `nim/r/radio_network_bgi_broadcast.nim` |
| Odin | `odin/r/radio_network_bgi_broadcast.odin` |
| Rust | `rust/r/radio_network_bgi_broadcast.rs` |
| V | `v/r/radio_network_bgi_broadcast.v` |
| Zig | `zig/r/radio_network_bgi_broadcast.zig` |

See [RIGHTS.md](RIGHTS.md), [INVENTORY.md](INVENTORY.md), and
[workload.json](workload.json). The bounded workload is registered in the
shared `i64_array_bytes_output` runner and verifier, and the benchmark appears
in [CATALOG](../../../CATALOG.md). No programs or checks were run.
