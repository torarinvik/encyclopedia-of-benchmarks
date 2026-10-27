# Approximate tandem K-repetitions

This package enumerates the chapter's Hamming-distance K-repetition factors
that extend beyond the two-block square profile already covered by
[`approximate_tandem_squares`](../approximate_tandem_squares/README.md). For a
factor of length `L` and period `p`, the total number of mismatches between
positions `x` and `x+p` over the factor must be at most `K`. To avoid duplicate
square outputs, this profile emits only `L > 2p`.

## Contract

ABI: `i64_array_bytes_output`; symbol: `approximate_tandem_k_repetitions`.
Input is `[n,K,symbols[n]]`, with `3<=n<=24`, `0<=K<=8`, and symbols in `0..3`.
The exact input length is `n+2` (at most 26 words). The output is little-endian
signed-64 data `[record_count,(start,length,period,mismatches)...]`, ordered by
start, period, then length. Positions are zero-based. The output is at most
34,504 bytes: for `n=24`, there are at most 1,078 eligible factor/period pairs.
Invalid input returns `-1`; null output or insufficient capacity returns
`-2` without writes. The declared 34,504-byte workspace covers the maximum
output buffer; each port uses scalar loop state and a counting pass before writing.

The implementation is a direct bounded enumeration of the chapter's
K-repetition definition, not the asymptotically efficient Kolpakov–Kucherov
algorithm. The chapter describes that algorithm's relationship to maximal
repetitions but does not include its complete procedure. Maximality, K-runs,
and K-edit repeats are not part of this package.

## Source and rights

Gregory Kucherov and Dina Sokol, “Approximate Tandem Repeats,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_24`](https://doi.org/10.1007/978-1-4939-2864-4_24),
Definitions 1 and the K-repetition entry in Key Results. The chapter is
copyrighted and grants no source-code license. All implementations are
clean-room bounded enumerators; no chapter prose, code, or figures are copied.
See [`RIGHTS.md`](RIGHTS.md).

Primary and independent verifier oracles:
[`approximate_tandem_k_repetitions_oracle.py`](../../approximate_tandem_k_repetitions_oracle.py)
and
[`approximate_tandem_k_repetitions_verifier_oracle.py`](../../approximate_tandem_k_repetitions_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/a/approximate_tandem_k_repetitions.c`](../../../c/a/approximate_tandem_k_repetitions.c) |
| C3 | [`c3/a/approximate_tandem_k_repetitions.c3`](../../../c3/a/approximate_tandem_k_repetitions.c3) |
| C++ | [`cpp/a/approximate_tandem_k_repetitions.cpp`](../../../cpp/a/approximate_tandem_k_repetitions.cpp) |
| Elisa | [`elisa/a/approximate_tandem_k_repetitions.elisa`](../../../elisa/a/approximate_tandem_k_repetitions.elisa) |
| Nim | [`nim/a/approximate_tandem_k_repetitions.nim`](../../../nim/a/approximate_tandem_k_repetitions.nim) |
| Odin | [`odin/a/approximate_tandem_k_repetitions.odin`](../../../odin/a/approximate_tandem_k_repetitions.odin) |
| Rust | [`rust/a/approximate_tandem_k_repetitions.rs`](../../../rust/a/approximate_tandem_k_repetitions.rs) |
| V | [`v/a/approximate_tandem_k_repetitions.v`](../../../v/a/approximate_tandem_k_repetitions.v) |
| Zig | [`zig/a/approximate_tandem_k_repetitions.zig`](../../../zig/a/approximate_tandem_k_repetitions.zig) |
