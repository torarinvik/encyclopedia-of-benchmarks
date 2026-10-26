# Exact uniform covering of a ring

This package implements the chapter's `RingCoveringExact` protocol from Paola Flocchini's *Encyclopedia of Algorithms* chapter “Uniform Covering of Rings and Lines by Memoryless Mobile Sensors,” DOI [`10.1007/978-1-4939-2864-4_594`](https://doi.org/10.1007/978-1-4939-2864-4_594).

## Bounded contract

- ABI: `i64_array_bytes_output`; input is `[n,visibility,steps,positions[n],activation_ids[steps]]`.
- There are `2 <= n <= 12` sensors on a ring of circumference `16n`; the desired gap is 16 coordinate units (one distance unit). Initial positions are distinct, increasing integer coordinates in `[0,16n)`, so IDs give the clockwise cyclic order. Visibility is an integer in `[32,16n]`, corresponding to the source assumption `V >= 2d`. There are at most 64 activations, each a sensor ID in `[0,n)`.
- Each activation completes one `Look-Compute-Move` before the next begins. For the activated sensor, let `gap` be its clockwise distance to its successor. If `gap > visibility`, it moves 16 units clockwise. Otherwise, if `gap > 16`, it moves to the point 16 units before its successor. If `gap <= 16`, it stays. This is one serial asynchronous execution trace; the schedule is supplied and may be unfair. The package makes no fairness or convergence claim for arbitrary schedules.
- Output is `[n,moved_count,final_positions[n],clockwise_gaps[n]]`, in signed-i64 little-endian words. The fixed 1/16 lattice is an exact discrete subset of the chapter's geometric protocol; no rounding is performed. Maximum input is 79 words and maximum output is 208 bytes. Invalid input returns `-1`; null or short output returns `-2` without writes.

## Provenance and rights

Source attribution: Paola Flocchini, “Uniform Covering of Rings and Lines by Memoryless Mobile Sensors,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_594`. The chapter and summarized research remain copyrighted. These ports are clean-room implementations of the mathematical protocol; no source code, prose, or figures are copied, and no source-code license is asserted. See [`RIGHTS.md`](RIGHTS.md).

## Package files

- [`workload.json`](workload.json)
- [primary position-update oracle](../../ring_exact_covering_protocol_oracle.py)
- [independent gap-state verifier oracle](../../ring_exact_covering_protocol_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/r/ring_exact_covering_protocol.c`](../../../c/r/ring_exact_covering_protocol.c) |
| C3 | [`c3/r/ring_exact_covering_protocol.c3`](../../../c3/r/ring_exact_covering_protocol.c3) |
| C++ | [`cpp/r/ring_exact_covering_protocol.cpp`](../../../cpp/r/ring_exact_covering_protocol.cpp) |
| Elisa | [`elisa/r/ring_exact_covering_protocol.elisa`](../../../elisa/r/ring_exact_covering_protocol.elisa) |
| Nim | [`nim/r/ring_exact_covering_protocol.nim`](../../../nim/r/ring_exact_covering_protocol.nim) |
| Odin | [`odin/r/ring_exact_covering_protocol.odin`](../../../odin/r/ring_exact_covering_protocol.odin) |
| Rust | [`rust/r/ring_exact_covering_protocol.rs`](../../../rust/r/ring_exact_covering_protocol.rs) |
| V | [`v/r/ring_exact_covering_protocol.v`](../../../v/r/ring_exact_covering_protocol.v) |
| Zig | [`zig/r/ring_exact_covering_protocol.zig`](../../../zig/r/ring_exact_covering_protocol.zig) |
