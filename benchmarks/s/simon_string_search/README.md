# Simon sparse-automaton string matching

This profile implements Simon’s exact string matcher using a compact
representation of the minimal deterministic automaton for prefixes of the
pattern. It recognizes the same match language as the local finite-automaton
matcher, but stores only the significant backward transitions and recovers the
forward transition from the next pattern symbol instead of building its dense
per-state, per-alphabet table. The search is an automaton traversal, distinct
from KMP’s prefix-failure walk.

## Contract

- ABI: i64_array_scalar; symbol: simon_string_search.
- Input: [text_length, pattern_length, text_symbols..., pattern_symbols...].
- Text length is 0..256; pattern length is 1..16; symbols are 0..15.
- The frame must contain exactly 2 + text_length + pattern_length values.
- Return the number of all matching start positions, including overlaps;
  return 0 when there are no matches and -2 for null, malformed, or out-of-range input.
- Maximum valid and parseable frame length: 274 signed 64-bit values.

The automaton uses one state for each pattern-prefix length, represented as
that length minus one. The forward edge from state p goes to p+1 when the next
pattern symbol matches. The sparse backward-edge list for p contains the
significant transitions to shorter nonzero prefixes; any absent transition
returns to the initial state -1. Preprocessing also records the longest
border state so the search can continue after a match and count overlaps.
There are O(m) significant transitions, preprocessing takes O(m), and
searching takes O(m+n) time with O(m) auxiliary space. The alphabet is bounded
to 16 symbols in this profile, but transition work does not scan the alphabet.

## Sources

- [Charras–Lecroq: Simon algorithm](https://igm.univ-mlv.fr/~lecroq/string/node9.html)
- Hancart, C. (1993), “On Simon’s string searching algorithm,” Information Processing Letters 47(2), 95–99.
- Simon, I. (1993), “String matching algorithms and automata,” Proceedings of the 1st American Workshop on String Processing, pp. 151–157.

These sources establish the algorithm and its provenance. The implementation
and fixtures are clean-room work; no source code or sample text is copied.

## Package files

- [Sparse-automaton primary reference](primary_oracle.py)
- [Independent direct-window reference](independent_oracle.py)
- [Workload](workload.json)
- [Rights and provenance](RIGHTS.md)
- [Static inventory](check_inventory.py)

## Language ports

| Language | File |
|---|---|
| C | [simon_string_search.c](../../../c/s/simon_string_search.c) |
| C3 | [simon_string_search.c3](../../../c3/s/simon_string_search.c3) |
| C++ | [simon_string_search.cpp](../../../cpp/s/simon_string_search.cpp) |
| Elisa | [simon_string_search.elisa](../../../elisa/s/simon_string_search.elisa) |
| Mojo | [simon_string_search.mojo](../../../mojo/s/simon_string_search.mojo) |
| Nim | [simon_string_search.nim](../../../nim/s/simon_string_search.nim) |
| Odin | [simon_string_search.odin](../../../odin/s/simon_string_search.odin) |
| Rust | [simon_string_search.rs](../../../rust/s/simon_string_search.rs) |
| V | [simon_string_search.v](../../../v/s/simon_string_search.v) |
| Zig | [simon_string_search.zig](../../../zig/s/simon_string_search.zig) |

No programs, scripts, checkers, tests, builds, compilers, or benchmarks were run.
