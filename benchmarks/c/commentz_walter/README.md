# Commentz–Walter multiple-pattern matching

This package implements Commentz–Walter algorithm B for exact matching of a
small set of patterns. It builds a trie from the reversed patterns, scans text
alignments from right to left, reports every terminal node reached, then skips
text using the algorithm's good-suffix and bad-character shift tables. The
result is the aggregate number of `(pattern, start-position)` matches, with
overlapping matches included.

## Contract

- ABI: `i64_array_scalar`, symbol `commentz_walter`.
- Input: `[P,N,lengths[P],pattern_symbols...,text_symbols...]` with pattern
  symbols concatenated in input order. `P` is 1 through 6, each pattern length
  is 1 through 8, the total pattern length is at most 32, and `N` is 0 through
  64. The exact frame length is `2+P+sum(lengths)+N`.
- Symbols are integer alphabet values 1 through 4. Patterns must be nonempty
  and unique. Invalid input, including duplicate patterns, returns -1.
- Maximum valid and parseable input lengths are 104 and 105 words. Null input
  returns -1 at declared lengths 0 and 105. The maximum valid result bound is
  `P*N = 384`.
- Every distinct pattern occurrence is counted separately, including
  overlapping occurrences and matches at the same text positions.

## Algorithm B shift tables

For each reverse-trie node `v`, `depth(v)` is the number of traversed symbols
and `word(v)` is the reverse-trie path. `set1(v)` contains nodes `u` for which
`word(v)` is a proper suffix of `word(u)`; `set2(v)` contains the terminal
nodes in `set1(v)`. If `wmin` is the shortest pattern length, the tables are:

- Root: `shift1(root)=1`, `shift2(root)=wmin`.
- Other nodes: `shift1(v)=min(wmin, depth(u)-depth(v) for u in set1(v))`.
- Other nodes: `shift2(v)=min(shift2(parent(v)), depth(u)-depth(v) for u in set2(v))`.
- For alphabet symbol `a`, `char(a)=min(wmin+1, depth(u) for nodes u labeled a)`.

At a scan position, if the walk stopped at node `v` after matching `j` symbols
and `c` is the preceding text symbol, or an out-of-alphabet sentinel before
the text begins, the next position advances by
`min(shift2(v), max(shift1(v), char(c)-j-1))`. The bounded clean-room ports
compute the suffix sets directly from trie paths; they do not replace the
right-to-left search with an Aho–Corasick pass. This is algorithm B; it does not
include algorithm B1's scanned-text stack and does not claim a linear worst-case
search bound. Preprocessing uses `O(T^2 L)` time for `T` trie nodes and maximum
pattern length `L`; the scan uses `O(N L + Z)` time in the worst case, where
`Z` is the number of reported matches. Trie paths and tables use `O(TL)` space.

## Distinction and provenance

The [NIST DADS entry](https://xlinux.nist.gov/dads/HTML/CommentzWalter.html)
describes Commentz–Walter as multiple-pattern matching that reads from pattern
ends and uses a finite-state structure. The primary reference is Beate
Commentz-Walter, “A string matching algorithm fast on the average,” ICALP 1979,
LNCS 71, pp. 118–132 ([DOI](https://doi.org/10.1007/3-540-09510-1_10)). The
algorithm-B tables and scan direction are also transcribed in §4.2 and Algorithm
4.2 of [Kelly's pattern-matching thesis](https://www.ccsl.carleton.ca/people/theses/Kelly_Master_Thesis_06.pdf).
Only the algorithm description and bibliographic details were used.

This is distinct from the local Aho–Corasick profile: Aho–Corasick consumes
each text symbol in a forward automaton pass, while this profile follows a
reversed trie from selected alignment ends and skips ahead with CW shift tables.
It is also distinct from backward single-pattern methods such as BNDM, which
have no multi-pattern reverse trie or CW suffix-shift tables.

See [RIGHTS](RIGHTS.md), [workload](workload.json), and the [static package
inventory](../../check_commentz_walter_package.py).

| Language | Port |
|---|---|
| C | [C](../../../c/c/commentz_walter.c) |
| C3 | [C3](../../../c3/c/commentz_walter.c3) |
| C++ | [C++](../../../cpp/c/commentz_walter.cpp) |
| Elisa | [Elisa](../../../elisa/c/commentz_walter.elisa) |
| Mojo | [Mojo](../../../mojo/c/commentz_walter.mojo) |
| Nim | [Nim](../../../nim/c/commentz_walter.nim) |
| Odin | [Odin](../../../odin/c/commentz_walter.odin) |
| Rust | [Rust](../../../rust/c/commentz_walter.rs) |
| V | [V](../../../v/c/commentz_walter.v) |
| Zig | [Zig](../../../zig/c/commentz_walter.zig) |
