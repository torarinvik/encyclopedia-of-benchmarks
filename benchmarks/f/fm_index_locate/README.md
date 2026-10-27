# FM-index locate with sampled suffix-array values

This bounded profile complements the existing FM-index `count(P)` package with
the chapter's `locate(P)` operation. It builds the BWT of a short text plus a
unique smallest sentinel, applies backward search to obtain the suffix-array
interval, then LF-walks from each row until it reaches a sampled suffix-array
value and reconstructs the text offset.

## Contract

ABI: `i64_array_bytes_output`. Input is `[n, text_symbols..., m,
pattern_symbols..., sample_stride]`, with text and pattern symbols in `1..4`,
`1<=n<=32`, `1<=m<=8`, and `1<=sample_stride<=n`. The maximum parseable input
is 43 words. The suffix array covers `text+[0]`; sample rows are exactly those
whose suffix-array value is divisible by the supplied stride. For every row in
the backward-search interval, LF is followed to the next sample and the result
is `(sample_value + number_of_LF_steps) mod (n+1)`. Returned text offsets are
listed in suffix-array order. A nonempty pattern cannot match the sentinel.

Output is little-endian signed-i64 `[match_count, offsets...]`, at most 264
bytes. Invalid input returns `-1`; null output or insufficient capacity
returns `-2` with no writes, after all input validation. The verifier uses a
direct text search and independently sorts matches by suffix order.

The chapter states a sampling rate `s=Θ(log^(1+ε)n)` for its asymptotic
space bound but leaves the finite rate as a parameter. This profile takes a
bounded explicit stride so each case is deterministic; it makes no compressed
space or asymptotic query-time claim. Rank uses direct bounded prefix scans.

## Source

Djamal Belazzougui, Veli Mäkinen, and Daniel Valenzuela, “Compressed Suffix
Array,” *Encyclopedia of Algorithms*, 2016, DOI
[10.1007/978-1-4939-2864-4_82](https://doi.org/10.1007/978-1-4939-2864-4_82),
FM-Index section, `OEBPS/AChap82.html`. The chapter explicitly gives backward
search, LF, sampled values, and `A[i]=samples[rank1(B,LF^k(i))]+k`. This is a
clean-room profile; no book prose or code is copied. See [RIGHTS.md](RIGHTS.md).

The primary and independent verifier oracles are
[`fm_index_locate_oracle.py`](../../fm_index_locate_oracle.py) and
[`fm_index_locate_verifier_oracle.py`](../../fm_index_locate_verifier_oracle.py).

| Language | Port |
|---|---|
| C | `c/f/fm_index_locate.c` |
| C3 | `c3/f/fm_index_locate.c3` |
| C++ | `cpp/f/fm_index_locate.cpp` |
| Elisa | `elisa/f/fm_index_locate.elisa` |
| Nim | `nim/f/fm_index_locate.nim` |
| Odin | `odin/f/fm_index_locate.odin` |
| Rust | `rust/f/fm_index_locate.rs` |
| V | `v/f/fm_index_locate.v` |
| Zig | `zig/f/fm_index_locate.zig` |
