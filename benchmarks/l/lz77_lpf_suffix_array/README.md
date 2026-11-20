# K3 suffix-array LPF factorization

This package implements the bounded K3 factorization profile from
Kärkkäinen, Kempa, and Puglisi’s “Linear Time Lempel-Ziv Factorization:
Simple, Fast, Small,” cited by the *Encyclopedia of Algorithms* entry
“Lempel-Ziv Compression.” It is a clean-room bounded profile.

## Contract

The exported symbol is `lz77_lpf_suffix_array` with the
`i64_array_bytes_output` ABI. Input is `[n, byte_0, ..., byte_(n-1)]`, where
`0 <= n <= 32` and each byte is in `0..255`. Valid frames have `n+1` words;
34 words are parseable so a trailing-word rejection can be represented.

The primary constructs a suffix array and inverse ranks. For a text start `i`,
`PSV[i]` is the text start stored at the greatest suffix-array rank below
`ISA[i]` whose SA value is less than `i`; `NSV[i]` is the text start at the
least suffix-array rank above `ISA[i]` whose SA value is less than `i`. These
are the previous and next strictly smaller SA values around suffix `i` in
lexicographic suffix order. It compares the LCPs with those two candidates.
It selects NSV only when its LCP is strictly greater; PSV wins ties. The
output records `(source_position, match_length)` for each greedy factor.
Source positions are zero-based. A zero length denotes a literal and uses
source sentinel `-1`; it advances one input byte. Positive lengths copy from
the chosen earlier start and advance by that length. LCPs use the original
input, so overlap is allowed.

Output is a sequence of little-endian signed 64-bit `(source,length)` pairs,
without a count prefix. At most 32 pairs are emitted, so maximum output is
512 bytes. Malformed or null input returns `-1`; null or insufficient output
returns `-2`. Input validation precedes output checks, and errors leave output
untouched. Empty input returns zero bytes.

This profile is distinct from the suite's `lz77_infinite_rightmost`, which
emits `(source,length,nextByte)` triples and consumes a following byte in
nonterminal tokens. It also differs from LZ-End and LZ78/LZW phrase rules.

The primary uses suffix sorting, monotone stacks for SA previous/next-smaller
values, and candidate LCP scans. The independent oracle scans every earlier
text position and uses direct suffix comparisons to locate the lexicographic
candidate on each side; it does not build a suffix array or use monotone
stacks. Both are O(n^3) worst case in this bounded profile, with O(n) auxiliary
storage. This package benchmarks the K3 factorization rule without claiming
the cited production algorithm's linear-time performance.

## Provenance and rights

The primary method is specified in the CPM 2013
[paper](https://cpm.cs.helsinki.fi/cpm13/16_kempa.pdf), especially K3 and its
LZ-Factor procedure. The encyclopedia chapter is Simon J. Puglisi,
[“Lempel-Ziv Compression,” DOI 10.1007/978-1-4939-2864-4_634](https://doi.org/10.1007/978-1-4939-2864-4_634).
Sources are cited for algorithm attribution only. Ports, fixtures, and
oracles are clean-room implementations; no upstream code, prose, or figures
are copied. See [RIGHTS.md](RIGHTS.md).

## Ports

- [C](../../../c/l/lz77_lpf_suffix_array.c)
- [C3](../../../c3/l/lz77_lpf_suffix_array.c3)
- [C++](../../../cpp/l/lz77_lpf_suffix_array.cpp)
- [Elisa](../../../elisa/l/lz77_lpf_suffix_array.elisa)
- [Mojo](../../../mojo/l/lz77_lpf_suffix_array.mojo)
- [Nim](../../../nim/l/lz77_lpf_suffix_array.nim)
- [Odin](../../../odin/l/lz77_lpf_suffix_array.odin)
- [Rust](../../../rust/l/lz77_lpf_suffix_array.rs)
- [V](../../../v/l/lz77_lpf_suffix_array.v)
- [Zig](../../../zig/l/lz77_lpf_suffix_array.zig)
