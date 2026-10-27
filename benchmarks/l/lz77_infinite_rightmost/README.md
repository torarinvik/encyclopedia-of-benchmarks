# Rightmost infinite-window LZ77 parsing

This package implements the infinite-window, rightmost LZ77 parsing variant
defined in the “Lempel-Ziv Compression” chapter (DOI
`10.1007/978-1-4939-2864-4_634`). It complements the existing bounded
Java/Python/Rust LZ77 source profiles, whose search/tie rules differ.

## Contract

Input is `[n, character_0, ..., character_(n-1)]`, with `0<=n<=64` and
printable ASCII codes 32–126. The exact frame has `1+n` signed-i64 words; 66
words are parseable to test the extra-word rejection path. For each suffix at
position `q`, search every earlier position `p<q` in the already parsed prefix.
Choose the longest match, resolving equal positive lengths in favor of the
largest `p` (the rightmost prior occurrence). Match comparison uses the
original input string, so overlapping phrase copies follow the source's
overlap semantics. A token is `(p,length,nextChar)`, storing the absolute
zero-based prior source position from the chapter; literals use p=0 and length
0. `nextChar` is the following ASCII code, or 0
when the matched phrase reaches end of input. A terminal token consumes only
its matched phrase; a nonterminal token consumes the phrase and next character.
Because the input excludes NUL, the terminal marker is unambiguous.

Output is a sequence of little-endian signed-i64 triples
`(sourcePosition,length,nextChar)`, without a token-count prefix. At most 64 tokens are
emitted, so the maximum output is 1536 bytes. Invalid framing/characters or
null input returns `-1`; null output or insufficient capacity returns `-2`;
errors leave output untouched. Empty input succeeds with zero output bytes.

The workload includes literals, overlapping matches, a rightmost equal-length
tie, terminal phrases, and malformed/capacity cases.
The primary oracle uses direct candidate scans; the verifier independently
builds a suffix-LCP table before selecting each rightmost longest match.

## Source and rights

Source: Simon J. Puglisi, “Lempel-Ziv Compression,” *Encyclopedia of
Algorithms*, DOI `10.1007/978-1-4939-2864-4_634`. The chapter is copyrighted by
Springer Science+Business Media New York. Ports and oracles are clean-room
implementations of the stated parsing rule; no book prose, figures, or
upstream code are copied. See [RIGHTS.md](RIGHTS.md).

## Ports

C, C3, C++, Elisa, Nim, Odin, Rust, V, and Zig export
`lz77_infinite_rightmost` through `i64_array_bytes_output`.
