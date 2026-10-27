# 1/e secretary threshold rule

This package profiles the classic secretary method described in “Secretary
Problems and Online Auctions,” DOI
[`10.1007/978-1-4939-2864-4_760`](https://doi.org/10.1007/978-1-4939-2864-4_760).
It observes the first `floor(n/e)` arrivals without selecting one, then picks
the first later candidate whose utility rank exceeds every observed rank.

Input is `[n,rank_0,...,rank_(n-1)]`, where `3<=n<=16` and the ranks form a
permutation of `1..n` (larger rank means greater utility). The sample count is
the exact integer table for `floor(n/e)` over that bound. The output is one
signed little-endian i64: the chosen zero-based arrival index, or `-1` when no
post-sample candidate exceeds the sample maximum. Invalid input returns `-1`;
null output or capacity below eight bytes returns `-2` without writing.

The input order is a supplied deterministic replay of the chapter's uniformly
random arrival-order assumption. The package does not generate random
permutations and makes no per-input probability or mechanism-design claim. It
implements only the single-choice threshold rule, not the chapter's
multiple-choice, matroid, submodular, or auction mechanisms.

| Language | Port |
|---|---|
| C | `c/s/secretary_1e_threshold.c` |
| C3 | `c3/s/secretary_1e_threshold.c3` |
| C++ | `cpp/s/secretary_1e_threshold.cpp` |
| Elisa | `elisa/s/secretary_1e_threshold.elisa` |
| Nim | `nim/s/secretary_1e_threshold.nim` |
| Odin | `odin/s/secretary_1e_threshold.odin` |
| Rust | `rust/s/secretary_1e_threshold.rs` |
| V | `v/s/secretary_1e_threshold.v` |
| Zig | `zig/s/secretary_1e_threshold.zig` |
