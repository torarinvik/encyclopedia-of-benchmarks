# PFR local forwarding decision

This profile isolates the angle-based local decision from “Probabilistic Data
Forwarding in Wireless Sensor Networks,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_301`](https://doi.org/10.1007/978-1-4939-2864-4_301).
The source rule forwards with probability 1 when the angle `φ` is at least
134 degrees and with probability `φ/π` below that threshold.

Input is `[angle_microdegrees, draw_index]`. The angle is an integer number of
microdegrees in `[0,180000000]`; `draw_index` is in `[0,999999]` and represents
the left-endpoint grid value `U=draw_index/1000000`. Below the threshold, the
port returns 1 exactly when `180*draw_index < angle_microdegrees`. This is an
integer-only deterministic replay of the supplied draw tape and avoids
cross-language floating-point differences. At and above 134 degrees the
result is always 1, independently of the draw.

Output is one little-endian signed i64, 1 for forward and 0 otherwise. The
million-point draw grid approximates a continuous uniform draw; the profile
does not claim the source's continuous-randomness probability guarantee. It
also does not model the two-phase front lifecycle, sensor-network topology,
collisions, activation ordering, or node failures.

Malformed input returns `-1`; null output or insufficient capacity returns
`-2` without writing. The primary oracle compares the integer cross-products;
the independent verifier computes the equivalent integer cutoff.

| Language | Port |
|---|---|
| C | `c/p/pfr_local_forward_decision.c` |
| C3 | `c3/p/pfr_local_forward_decision.c3` |
| C++ | `cpp/p/pfr_local_forward_decision.cpp` |
| Elisa | `elisa/p/pfr_local_forward_decision.elisa` |
| Nim | `nim/p/pfr_local_forward_decision.nim` |
| Odin | `odin/p/pfr_local_forward_decision.odin` |
| Rust | `rust/p/pfr_local_forward_decision.rs` |
| V | `v/p/pfr_local_forward_decision.v` |
| Zig | `zig/p/pfr_local_forward_decision.zig` |
