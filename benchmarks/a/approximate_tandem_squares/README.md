# Approximate tandem squares

This bounded profile implements the chapter’s simplest approximate tandem repeat: an approximate square is two adjacent equal-length blocks whose Hamming distance is at most `K`. It enumerates every qualifying factor, ordered by start position and then period. This is distinct from approximate substring edit-distance matching, which compares a pattern against arbitrary text substrings.

The input is `[n,K,symbols...]`, where `2<=n<=32`, `0<=K<=8`, and each symbol is in `0..3`. For each start and period satisfying `2*period <= n-start`, compare the first block `symbols[start:start+period]` with the adjacent block. Emit `[count,(start,period,mismatches)*]` as little-endian signed 64-bit values. At most 256 records occur, so input is at most 34 words and output at most 770 words (6,160 bytes). Invalid input returns `-1`; null or insufficient output returns `-2` without writing.

The profile covers approximate squares (the chapter’s first definition). It does not implement the more involved maximal K-repetition/K-run enumeration or K-edit repeats, which have different interval and distance semantics.

## Implementations

| Language | Source |
|---|---|
| C | [`c/a/approximate_tandem_squares.c`](../../../c/a/approximate_tandem_squares.c) |
| C3 | [`c3/a/approximate_tandem_squares.c3`](../../../c3/a/approximate_tandem_squares.c3) |
| C++ | [`cpp/a/approximate_tandem_squares.cpp`](../../../cpp/a/approximate_tandem_squares.cpp) |
| Elisa | [`elisa/a/approximate_tandem_squares.elisa`](../../../elisa/a/approximate_tandem_squares.elisa) |
| Nim | [`nim/a/approximate_tandem_squares.nim`](../../../nim/a/approximate_tandem_squares.nim) |
| Odin | [`odin/a/approximate_tandem_squares.odin`](../../../odin/a/approximate_tandem_squares.odin) |
| Rust | [`rust/a/approximate_tandem_squares.rs`](../../../rust/a/approximate_tandem_squares.rs) |
| V | [`v/a/approximate_tandem_squares.v`](../../../v/a/approximate_tandem_squares.v) |
| Zig | [`zig/a/approximate_tandem_squares.zig`](../../../zig/a/approximate_tandem_squares.zig) |

Primary oracle: [`approximate_tandem_squares_oracle.py`](../../approximate_tandem_squares_oracle.py). Independent period-first verifier: [`approximate_tandem_squares_verifier_oracle.py`](../../approximate_tandem_squares_verifier_oracle.py).

## Attribution and rights

Based on the problem definitions in Gregory Kucherov and Dina Sokol, “Approximate Tandem Repeats,” *Encyclopedia of Algorithms* (2016), DOI [10.1007/978-1-4939-2864-4_24](https://doi.org/10.1007/978-1-4939-2864-4_24). This is an independently written implementation of the stated bounded profile; no book prose, code, or figures are reproduced. The book remains copyrighted by Springer; this attribution does not grant redistribution rights to its contents.
