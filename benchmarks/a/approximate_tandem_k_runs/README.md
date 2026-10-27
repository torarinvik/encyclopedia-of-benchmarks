# Approximate tandem K-runs

This package enumerates longer-than-square factors satisfying the chapter's
K-run rule. For each factor of length `L` and period `p`, every contained
length-`2p` window must have at most `K` Hamming mismatches between its two
halves. The total mismatches over the whole factor may exceed `K`. The package
omits `L=2p` records because the existing
[`approximate_tandem_squares`](../approximate_tandem_squares/README.md) profile
already covers that boundary.

## Contract

ABI: `i64_array_bytes_output`; symbol: `approximate_tandem_k_runs`. Input is
`[n,K,symbols[n]]`, with `3<=n<=24`, `0<=K<=8`, and symbols in `0..3`. The
exact input length is `n+2` (at most 26 words). Output is little-endian
signed-64 data `[record_count,(start,length,period,max_window_mismatches)...]`,
ordered by start, period, then length; positions are zero-based. At most 1,078
factor/period pairs qualify, so output is bounded by 34,504 bytes. Invalid
input returns `-1`; null output or insufficient capacity returns `-2` without
writes. The declared 34,504-byte workspace covers the maximum output buffer;
each port uses scalar loop state and a counting pass before writing.

This is direct bounded enumeration of Definition 2. It is not the chapter's
more involved efficient K-run algorithm, which the chapter describes as using
a bootstrapping technique without giving full pseudocode. The package does
not assert maximality or implement K-repetitions or K-edit repeats.

## Source and rights

Gregory Kucherov and Dina Sokol, “Approximate Tandem Repeats,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_24`](https://doi.org/10.1007/978-1-4939-2864-4_24),
Definition 2 and the K-run entry in Key Results. The chapter is copyrighted and
grants no source-code license. The ports are clean-room bounded enumerators;
no book prose, figures, or code are copied. See [`RIGHTS.md`](RIGHTS.md).

Oracles:
[`approximate_tandem_k_runs_oracle.py`](../../approximate_tandem_k_runs_oracle.py)
and
[`approximate_tandem_k_runs_verifier_oracle.py`](../../approximate_tandem_k_runs_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/a/approximate_tandem_k_runs.c`](../../../c/a/approximate_tandem_k_runs.c) |
| C3 | [`c3/a/approximate_tandem_k_runs.c3`](../../../c3/a/approximate_tandem_k_runs.c3) |
| C++ | [`cpp/a/approximate_tandem_k_runs.cpp`](../../../cpp/a/approximate_tandem_k_runs.cpp) |
| Elisa | [`elisa/a/approximate_tandem_k_runs.elisa`](../../../elisa/a/approximate_tandem_k_runs.elisa) |
| Nim | [`nim/a/approximate_tandem_k_runs.nim`](../../../nim/a/approximate_tandem_k_runs.nim) |
| Odin | [`odin/a/approximate_tandem_k_runs.odin`](../../../odin/a/approximate_tandem_k_runs.odin) |
| Rust | [`rust/a/approximate_tandem_k_runs.rs`](../../../rust/a/approximate_tandem_k_runs.rs) |
| V | [`v/a/approximate_tandem_k_runs.v`](../../../v/a/approximate_tandem_k_runs.v) |
| Zig | [`zig/a/approximate_tandem_k_runs.zig`](../../../zig/a/approximate_tandem_k_runs.zig) |
