# P2P Chord finger lookup

This is a bounded static Chord lookup profile for the P2P chapter (DOI [`10.1007/978-1-4939-2864-4_272`](https://doi.org/10.1007/978-1-4939-2864-4_272)). It measures lookup over a supplied, immutable ring and canonical finger table. Join/leave maintenance and other overlay families discussed in the chapter are outside this profile.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[bits,node_count,start_index,key,node_ids...,finger_indices...]`.
- `1 <= bits <= 6`; node IDs are strictly increasing members of `[0,2^bits)`. `2 <= node_count <= min(16,2^bits)`. The start and finger entries are indexes into the sorted node array; the key is a ring identifier.
- Finger entries are row-major by node then level, with levels `i=0..bits-1`. Every entry must equal the index of `successor((node_id + 2^i) mod 2^bits)`, wrapping to the first node.
- The key owner is the first node ID greater than or equal to the key, or the first node after wrap. Starting at `start_index`, route through the highest-level finger that advances clockwise without passing the owner. Output the visited node IDs, including the start and owner, as little-endian signed-i64 words.
- Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writing. Maximum output capacity is 128 bytes (16 node IDs).

The profile fixes membership and finger links so calls measure the chapter's lookup behavior without mixing in network transport, maintenance, or random ID generation. The supplied table is checked against the canonical static ring before routing.

## Provenance and rights

Source: “P2P,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_272`, describing binary ring IDs, exponentially spaced shortcuts, and greedy distance reduction. This implementation is clean-room and uses only the algorithm description; it does not copy book prose or code. The chapter does not grant a source-code license. See [`RIGHTS.md`](RIGHTS.md).

## Files

- [`workload.json`](workload.json)
- [Primary route oracle](../../p2p_chord_finger_lookup_oracle.py)
- [Independent verifier oracle](../../p2p_chord_finger_lookup_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/p/p2p_chord_finger_lookup.c`](../../../c/p/p2p_chord_finger_lookup.c) |
| C3 | [`c3/p/p2p_chord_finger_lookup.c3`](../../../c3/p/p2p_chord_finger_lookup.c3) |
| C++ | [`cpp/p/p2p_chord_finger_lookup.cpp`](../../../cpp/p/p2p_chord_finger_lookup.cpp) |
| Elisa | [`elisa/p/p2p_chord_finger_lookup.elisa`](../../../elisa/p/p2p_chord_finger_lookup.elisa) |
| Nim | [`nim/p/p2p_chord_finger_lookup.nim`](../../../nim/p/p2p_chord_finger_lookup.nim) |
| Odin | [`odin/p/p2p_chord_finger_lookup.odin`](../../../odin/p/p2p_chord_finger_lookup.odin) |
| Rust | [`rust/p/p2p_chord_finger_lookup.rs`](../../../rust/p/p2p_chord_finger_lookup.rs) |
| V | [`v/p/p2p_chord_finger_lookup.v`](../../../v/p/p2p_chord_finger_lookup.v) |
| Zig | [`zig/p/p2p_chord_finger_lookup.zig`](../../../zig/p/p2p_chord_finger_lookup.zig) |
