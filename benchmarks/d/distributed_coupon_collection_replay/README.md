# Distributed coupon-collection replay

This profile implements the bounded coupon-collection process described in
“Randomized Gossiping in Radio Networks,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_324`](https://doi.org/10.1007/978-1-4939-2864-4_324).
The source models `n` bins containing copies of coupons: in each step, every
bin opens independently with probability `1/n`; coupons are collected only
when exactly one bin opens, in which case all coupons in that bin are obtained.

The input is `[n,c,k,T,bin_masks[n],open_bits[T*n]]`, where `2<=n<=8`,
`1<=c<=8`, `1<=k<=n`, and `1<=T<=8`. Each mask encodes the coupons in one bin,
and every coupon must occur in at least `k` distinct bins. The supplied open
bits are step-major: `open_bits[t*n+b]` gives the open/closed outcome for bin
`b` in step `t` (`1` means open). These bits replay the source process's
Bernoulli outcomes; the implementation does not generate random values.

The output is `[collected_coupon_mask,singleton_open_steps]` as two
little-endian i64 values (16 bytes). A step with zero or multiple open bins
collects nothing. Malformed input returns `-1`; null output or insufficient
capacity returns `-2` without writing. This is a deterministic replay of a
bounded source-defined process: it makes no probability, expectation, or
gossiping-completion claim. It is separate from DOI322's radio `Decay` protocol
and does not model the radio network's topology or collisions.

The primary oracle scans the open-bin list per step. The independent verifier
forms an open-bin bitmask and accepts a collection step only when its
population count is one.

| Language | Port |
|---|---|
| C | `c/d/distributed_coupon_collection_replay.c` |
| C3 | `c3/d/distributed_coupon_collection_replay.c3` |
| C++ | `cpp/d/distributed_coupon_collection_replay.cpp` |
| Elisa | `elisa/d/distributed_coupon_collection_replay.elisa` |
| Nim | `nim/d/distributed_coupon_collection_replay.nim` |
| Odin | `odin/d/distributed_coupon_collection_replay.odin` |
| Rust | `rust/d/distributed_coupon_collection_replay.rs` |
| V | `v/d/distributed_coupon_collection_replay.v` |
| Zig | `zig/d/distributed_coupon_collection_replay.zig` |
