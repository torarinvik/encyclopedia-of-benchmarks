# Backward oracle matching

This draft implements first-occurrence exact search with a factor oracle built
for the reversed pattern. For each text window it follows oracle transitions
from right to left; a missing transition permits a shift past that character. The factor
oracle can accept extra factors, but it accepts no other word of the full
pattern length. BNDM instead simulates a nondeterministic suffix automaton
with a bit mask; Horspool uses a window-end bad-character table.

The intended `i64_array_scalar` input is `[n,m,text...,pattern...]`, with
`0<=n<=4096`, `0<=m<=63`, exact length `2+n+m`, and lowercase ASCII byte
values. All bytes are checked before search. Return the first zero-based
match, 0 for an empty pattern, -1 for absence, and -2 for malformed or null
input. This matches the existing BNDM and Bitap domain for comparison.

The draft uses a dense 26-symbol transition table for at most 64 states.
Oracle construction uses `O(m*alphabet)` space for this representation;
the search takes `O(n*m)` time in the worst case. The automaton and matcher
are based on the independently described factor-oracle method of Allauzen,
Crochemore and Raffinot, [*Factor Oracle: A New Structure for Pattern
Matching*](https://citeseerx.ist.psu.edu/document?doi=4799c88ba0bd0626f9e4916ef3f530e2c8e677bf&repid=rep1&type=pdf)
(1999). Algorithmic ideas and bibliographic facts only are used.

Ten language drafts, two references, workload, and scalar runner/verifier
integration are present. The verifier source specifies exhaustive short binary
and ternary inputs, long-pattern boundaries, maximum frames, and null inputs. The Elisa
draft uses a bounded view and fixed indexed arrays. Nothing has been compiled
or run.

| Language | Draft source |
| --- | --- |
| C | [C](../../../c/b/backward_oracle_match.c) |
| C3 | [C3](../../../c3/b/backward_oracle_match.c3) |
| C++ | [C++](../../../cpp/b/backward_oracle_match.cpp) |
| Elisa | [Elisa](../../../elisa/b/backward_oracle_match.elisa) |
| Mojo | [Mojo](../../../mojo/b/backward_oracle_match.mojo) |
| Nim | [Nim](../../../nim/b/backward_oracle_match.nim) |
| Odin | [Odin](../../../odin/b/backward_oracle_match.odin) |
| Rust | [Rust](../../../rust/b/backward_oracle_match.rs) |
| V | [V](../../../v/b/backward_oracle_match.v) |
| Zig | [Zig](../../../zig/b/backward_oracle_match.zig) |
