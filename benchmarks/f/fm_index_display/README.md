# FM-index display

This package implements the `display(i,j)` substring query from the FM-index
chapter using its sampled inverse-suffix-array and BWT-inversion procedure. It
is separate from [`fm_index_count`](../fm_index_count/README.md), which reports
pattern occurrence counts, and [`fm_index_locate`](../fm_index_locate/README.md),
which reports matching offsets.

## Contract

ABI: `i64_array_bytes_output`. Input is `[n,text_symbols...,i,j,stride]` with
`1<=n<=32`, alphabet symbols `1..4`, zero-based inclusive bounds
`0<=i<=j<n`, and `1<=stride<=n`. The input has exactly `n+4` words and at most
36 words. The output is the requested substring as raw one-byte alphabet
symbols, in forward text order; success returns its byte length (1..32).
Invalid input returns `-1`; null output or insufficient capacity returns
`-2` without writing. Maximum output is 32 bytes and workspace is 4,096 bytes.

The profile builds the suffix array, inverse suffix array, BWT, and LF mapping
for the bounded text. In the chapter's one-based notation, positions `j'·s`
are sampled with `SA⁻¹[j'·s]`. Thus zero-based suffix positions `p` are sampled
when `(p+1) % stride == 0`; the terminal sentinel position `n` is also retained
to make every endpoint queryable. For the requested right endpoint `j`, it
starts at the smallest sampled text position `p>j`, uses LF to walk backward,
skips any overhang above `j`, collects `T[j]` through `T[i]`, and reverses
those bytes. This is the chapter's source-described sample-after-right-endpoint
rule with explicit zero-based indexing and sentinel handling. The profile does
not claim compressed-space or asymptotic index
construction bounds; preprocessing is included in each call.

## Source and rights

Veli Mäkinen and Gonzalo Navarro, “Compressed Text Indexing,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_83`](https://doi.org/10.1007/978-1-4939-2864-4_83),
FM-index section, paragraph on general `display(i,j)` queries. The chapter
specifies regular text-position sampling with `SA⁻¹` samples and BWT inversion
from the smallest sample strictly after `j`. The ports are clean-room
implementations; no chapter prose, figures, or source code are copied. See
[`RIGHTS.md`](RIGHTS.md).

Primary and independent verifier oracles:
[`fm_index_display_oracle.py`](../../fm_index_display_oracle.py) and
[`fm_index_display_verifier_oracle.py`](../../fm_index_display_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/f/fm_index_display.c`](../../../c/f/fm_index_display.c) |
| C3 | [`c3/f/fm_index_display.c3`](../../../c3/f/fm_index_display.c3) |
| C++ | [`cpp/f/fm_index_display.cpp`](../../../cpp/f/fm_index_display.cpp) |
| Elisa | [`elisa/f/fm_index_display.elisa`](../../../elisa/f/fm_index_display.elisa) |
| Nim | [`nim/f/fm_index_display.nim`](../../../nim/f/fm_index_display.nim) |
| Odin | [`odin/f/fm_index_display.odin`](../../../odin/f/fm_index_display.odin) |
| Rust | [`rust/f/fm_index_display.rs`](../../../rust/f/fm_index_display.rs) |
| V | [`v/f/fm_index_display.v`](../../../v/f/fm_index_display.v) |
| Zig | [`zig/f/fm_index_display.zig`](../../../zig/f/fm_index_display.zig) |
