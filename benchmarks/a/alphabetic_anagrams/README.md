# Alphabetic Anagrams

Compute the 1-based lexicographic rank of a word among the distinct
permutations of its own symbols. Repeated symbols produce one arrangement
each, not one arrangement per occurrence identity.

## Contract

Input is `[n, symbol_0, ..., symbol_(n-1)]`, with exactly `n+1` signed 64-bit
words, `0 <= n <= 8`, and symbols in `0..25` (ordered alphabet values). The
empty word has rank 1. Invalid framing, symbols outside the alphabet, and null
input return `-1`. A valid result lies in `1..40320`; up to one trailing word is
accepted by the parser only so it can be rejected.

## Multiset rank

For remaining multiplicities `f[c]` across `r` positions, the number of
distinct arrangements is the multinomial coefficient
`r! / product(f[c]!)`. At each position, try each still-available smaller
symbol in turn. Its lexicographic block has size
`ways * f[c] / r`; add those blocks to the rank. Then retain the block for the
actual symbol using the same formula and remove one copy. Start the rank at 1.
This is a multiplicity-aware ranking method. It differs from the local
[`kth_lexicographic_permutation`](../../k/kth_lexicographic_permutation/README.md),
which selects a zero-based rank among distinct symbols, and
[`unique_permutation`](../../u/unique_permutation/README.md), which emits
permutations by backtracking rather than ranking a single input word.

The primary method follows Knuth's lexicographic permutation ranking treatment
and the multinomial count for multisets in the [NIST DLMF](https://dlmf.nist.gov/26.16).
The independent reference enumerates each distinct arrangement from the
sorted multiset via the next-permutation successor and counts until it reaches
the target. With `n <= 8`, it considers at most `8!` distinct arrangements.

## Sources and ports

Generic method source: Knuth, [*The Art of Computer Programming*, Volume 4A](https://cs.stanford.edu/~knuth/taocp.html), §7.2.1.2; NIST [DLMF §26.16](https://dlmf.nist.gov/26.16).
See [`RIGHTS.md`](RIGHTS.md) and [`INVENTORY.md`](INVENTORY.md).

| Language | Source |
| --- | --- |
| C | [`c/a/alphabetic_anagrams.c`](../../../c/a/alphabetic_anagrams.c) |
| C3 | [`c3/a/alphabetic_anagrams.c3`](../../../c3/a/alphabetic_anagrams.c3) |
| C++ | [`cpp/a/alphabetic_anagrams.cpp`](../../../cpp/a/alphabetic_anagrams.cpp) |
| Elisa | [`elisa/a/alphabetic_anagrams.elisa`](../../../elisa/a/alphabetic_anagrams.elisa) |
| Mojo | [`mojo/a/alphabetic_anagrams.mojo`](../../../mojo/a/alphabetic_anagrams.mojo) |
| Nim | [`nim/a/alphabetic_anagrams.nim`](../../../nim/a/alphabetic_anagrams.nim) |
| Odin | [`odin/a/alphabetic_anagrams.odin`](../../../odin/a/alphabetic_anagrams.odin) |
| Rust | [`rust/a/alphabetic_anagrams.rs`](../../../rust/a/alphabetic_anagrams.rs) |
| V | [`v/a/alphabetic_anagrams.v`](../../../v/a/alphabetic_anagrams.v) |
| Zig | [`zig/a/alphabetic_anagrams.zig`](../../../zig/a/alphabetic_anagrams.zig) |
