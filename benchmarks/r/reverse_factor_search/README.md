# Reverse Factor Search

Input is `[n,m,text...,pattern...]`, with `0<=n<=4096`, `1<=m<=128`, and
symbols in `0..3`. The scalar result packs all possibly overlapping match
offsets as `(count<<36)|(sum<<12)|xor`; malformed input returns `-1`.

Reverse Factor builds the suffix automaton of the reversed pattern. At each
alignment it scans the text window backward, continuing while automaton
transitions exist. Terminal states record suffixes of the reversed pattern;
the most recent terminal state determines a safe shift, while a full match
uses the pattern period. This uses the automaton's factor recognition and
terminal suffix states, rather than Two-Way critical factorization, BNDM's
bit-parallel state, or Reverse Colussi's ordered comparisons and shift tables.

For the fixed four-symbol alphabet, automaton construction takes `O(m)` time
and `O(m)` space. Searching is `O(m*n)` in the worst case; the published
average inspection bound is `O(n*log_4(m)/m)` for `m>=2`, with `O(n)` work
when `m=1`. The ports also use a bounded copy of the text.

The algorithm follows Lecroq's [Reverse Factor description](https://igm.univ-mlv.fr/~lecroq/string/node23.html)
and the 1994 [analysis by Crochemore et al.](https://doi.org/10.1007/BF01185427).
Only algorithm ideas were consulted; the benchmark code, contract, fixtures,
and documentation are independently authored. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/r/reverse_factor_search.c](../../../c/r/reverse_factor_search.c) |
| C3 | [c3/r/reverse_factor_search.c3](../../../c3/r/reverse_factor_search.c3) |
| C++ | [cpp/r/reverse_factor_search.cpp](../../../cpp/r/reverse_factor_search.cpp) |
| Elisa | [elisa/r/reverse_factor_search.elisa](../../../elisa/r/reverse_factor_search.elisa) |
| Mojo | [mojo/r/reverse_factor_search.mojo](../../../mojo/r/reverse_factor_search.mojo) |
| Nim | [nim/r/reverse_factor_search.nim](../../../nim/r/reverse_factor_search.nim) |
| Odin | [odin/r/reverse_factor_search.odin](../../../odin/r/reverse_factor_search.odin) |
| Rust | [rust/r/reverse_factor_search.rs](../../../rust/r/reverse_factor_search.rs) |
| V | [v/r/reverse_factor_search.v](../../../v/r/reverse_factor_search.v) |
| Zig | [zig/r/reverse_factor_search.zig](../../../zig/r/reverse_factor_search.zig) |
