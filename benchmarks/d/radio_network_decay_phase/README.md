# Radio-network Decay phase

This bounded profile follows the `Decay(k,m)` phase in “Randomized
Broadcasting in Radio Networks,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_322`](https://doi.org/10.1007/978-1-4939-2864-4_322).
It executes one synchronized phase on an undirected simple radio graph.

The input is `[n,k,initial_mask,adjacency_mask[n],coin_bits[n*k]]`, with
`2<=n<=8` and `1<=k<=8`. Adjacency masks use vertex-index bits and must describe
a symmetric loop-free graph. The initial informed mask must be nonempty. Coin
bits are node-major: bit `(v*k+t)` controls node `v` after slot `t`. In each
slot, every still-active initially informed node transmits to all neighbors.
A noninitial receiver learns the message only if exactly one neighbor
transmits in that slot; zero senders or a collision delivers nothing. After
sending, a coin bit of 0 stops that sender and 1 lets it continue, except that
all senders stop at the end of slot `k`. Newly informed nodes are reported but
do not transmit during this phase; they can join a later phase in the full
broadcast algorithm.

The output is `[newly_informed_mask,total_transmissions]` as two little-endian
i64 values (16 bytes). Malformed input returns `-1`; null output or insufficient
capacity returns `-2` without writing. The bounded profile replays supplied
fair-coin bits deterministically. It does not generate randomness, establish
probability guarantees, model capture/interference beyond strict singleton
reception, or implement the repeated global broadcast schedule.

The primary oracle simulates active senders and scans each sender's neighbors.
The independent verifier forms a sender bitmask each round and counts its
intersection with each receiver's adjacency mask.

| Language | Port |
|---|---|
| C | `c/d/radio_network_decay_phase.c` |
| C3 | `c3/d/radio_network_decay_phase.c3` |
| C++ | `cpp/d/radio_network_decay_phase.cpp` |
| Elisa | `elisa/d/radio_network_decay_phase.elisa` |
| Nim | `nim/d/radio_network_decay_phase.nim` |
| Odin | `odin/d/radio_network_decay_phase.odin` |
| Rust | `rust/d/radio_network_decay_phase.rs` |
| V | `v/d/radio_network_decay_phase.v` |
| Zig | `zig/d/radio_network_decay_phase.zig` |
