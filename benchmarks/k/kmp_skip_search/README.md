# KmpSkip Search

Input is `[n,m,text...,pattern...]`: `0<=n<=4096`, `1<=m<=128`, with
symbols in `0..3`. The output packs the count, sum, and xor of every
possibly overlapping match offset as `(count<<36)|(sum<<12)|xor`.
Malformed input returns `-1`.

KmpSkip combines Skip Search's per-symbol position buckets with Morris–Pratt
and Knuth–Morris–Pratt shifts. A rightmost verified text position (`wall`)
lets successive candidate windows reuse comparisons. At each step, the
algorithm reconciles the next bucket-derived start with the next KMP-derived
start; plain KMP does not use the buckets, and Alpha Skip Search uses sampled
fixed-length factors followed by full candidate verification. This profile
uses a four-symbol alphabet, so the bucket table has constant size.

Pattern preprocessing is `O(m+4)` time and space. The KmpSkip search phase is
`O(n)` time; auxiliary storage is `O(m+4)` beyond the bounded text copy.
Packed values remain below `2^49` for these bounds.

The algorithm idea follows Charras and Lecroq's [KmpSkip description](https://igm.univ-mlv.fr/~lecroq/string/node32.html),
their [1998 paper](https://doi.org/10.1007/BFb0030780), and the [NIST DADS index entry](https://xlinux.nist.gov/dads/HTML/kmpskipsrch.html).
The sources were consulted for the algorithm only; this contract, code,
fixtures, and references are independently authored. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/k/kmp_skip_search.c](../../../c/k/kmp_skip_search.c) |
| C3 | [c3/k/kmp_skip_search.c3](../../../c3/k/kmp_skip_search.c3) |
| C++ | [cpp/k/kmp_skip_search.cpp](../../../cpp/k/kmp_skip_search.cpp) |
| Elisa | [elisa/k/kmp_skip_search.elisa](../../../elisa/k/kmp_skip_search.elisa) |
| Mojo | [mojo/k/kmp_skip_search.mojo](../../../mojo/k/kmp_skip_search.mojo) |
| Nim | [nim/k/kmp_skip_search.nim](../../../nim/k/kmp_skip_search.nim) |
| Odin | [odin/k/kmp_skip_search.odin](../../../odin/k/kmp_skip_search.odin) |
| Rust | [rust/k/kmp_skip_search.rs](../../../rust/k/kmp_skip_search.rs) |
| V | [v/k/kmp_skip_search.v](../../../v/k/kmp_skip_search.v) |
| Zig | [zig/k/kmp_skip_search.zig](../../../zig/k/kmp_skip_search.zig) |
