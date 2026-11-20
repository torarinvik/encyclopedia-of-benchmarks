# Galil–Giancarlo string search

This package implements the Galil–Giancarlo refinement of Colussi's exact
string search. It retains Colussi's linear preprocessing and ordered
nohole/hole comparisons. For a pattern with a repeated initial run followed by
a different symbol, the search also uses the `heavy` state to scan the
remembered text prefix and resume at the correct nohole. A constant-symbol
pattern uses a linear run-count path.

## Bounded profile

The exported `galil_giancarlo_search` function uses the
`i64_array_scalar` ABI. Input is `[n,m,text...,pattern...]`, with
`0 <= n <= 4096`, `1 <= m <= 128`, symbols in `0..3`, and exact length
`2+n+m`. A single trailing word is parseable but invalid. The result packs
`(match_count << 36) | (sum_of_offsets << 12) | xor_of_offsets`, including
overlapping matches. The workspace bound is 49,152 bytes.

The nonconstant-pattern branch computes `ell`, the last index in the initial
run of the first symbol, and applies Galil–Giancarlo's remembered-prefix
transition after a heavy Colussi shift. Text-end checks make this bounded
profile safe without sentinels in the text buffer. Invalid input returns `-1`.
All outputs fit in a nonnegative signed 64-bit value for the stated bounds.

The local `colussi_search` has the same table preprocessing and ordered scan,
but lacks Galil–Giancarlo's heavy remembered-prefix resumption; its stated
comparison bound is `3n/2`, while Galil and Giancarlo sharpen this to
`4n/3 - m/3`. This is a search refinement, not another spelling of KMP or a
generic substring scan. The pattern-constant path is included because the
source treats powers of one symbol separately.

The implementation follows the method in Galil and Giancarlo, “On the Exact
Complexity of String Matching: Upper Bounds,” *SIAM Journal on Computing*
21(3), 407–437 (1992),
[doi:10.1137/0221028](https://doi.org/10.1137/0221028), with the transition
description cross-checked against Lecroq's [Galil–Giancarlo algorithm page](https://igm.univ-mlv.fr/~lecroq/string/node11.html).
Only algorithm ideas were consulted; code and the bounded profile are written
independently. See [RIGHTS.md](RIGHTS.md).

[`primary_oracle.py`](primary_oracle.py) reproduces the ordered scan and heavy
resumption. [`independent_oracle.py`](independent_oracle.py) checks all
possible alignments directly. [`workload.json`](workload.json) covers the
constant-symbol branch, a repeated-prefix nonconstant pattern, overlaps,
empty text, and invalid frames.
