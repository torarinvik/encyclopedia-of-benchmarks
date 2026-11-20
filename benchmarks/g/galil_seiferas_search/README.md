# Galil–Seiferas exact string matching

This profile implements the Galil–Seiferas time-space-optimal exact matcher.
Preprocessing finds a perfect factorization of the pattern using prefix-period
searches with the constant k=4. Search keeps the factorization's p1/q1 period
state and resumes comparisons across safe p1 shifts. It uses a constant
number of integer variables rather than a KMP failure table or Two-Way's
critical-factorization memory state.

The local Two-Way matcher and this matcher recognize the same exact-match
language, but their search procedures are distinct: Two-Way uses critical
factorization and period-based memory; Galil–Seiferas finds a perfect
factorization by searching for one or two prefix periods.

## Contract

- ABI: i64_array_scalar; symbol: galil_seiferas_search.
- Input: [text_length, pattern_length, text_symbols..., pattern_symbols...].
- Text length is 0..128; pattern length is 1..32; symbols are 0..15.
- The frame must contain exactly 2 + text_length + pattern_length values.
- Return the total number of matching start positions, including overlaps;
  return 0 for no matches and -2 for null, malformed, or out-of-range input.
- Maximum valid and parseable frame length: 162 signed 64-bit values.

The implementation uses the Charras–Lecroq newP1, newP2, parse, and search
rules with explicit bounds instead of sentinel reads or recursion. The
factorization is O(m) time and O(1) auxiliary space; searching is O(n) time
and the source gives a 5n comparison bound for k=4. The independent oracle
checks every alignment directly.

## Sources

- [Charras–Lecroq: Galil–Seiferas algorithm](https://igm.univ-mlv.fr/~lecroq/string/node25.html)
- Galil, Z. and Seiferas, J. (1983), “Time-space-optimal string matching,” Journal of Computer and System Sciences 26(3), 280–294, [doi:10.1016/0022-0000(83)90002-8](https://doi.org/10.1016/0022-0000(83)90002-8).

The references are used for the algorithm and provenance only. The
implementations and fixtures are clean-room work; no source code or sample
text is copied.

## Package files

- [Perfect-factorization primary reference](primary_oracle.py)
- [Independent direct-window reference](independent_oracle.py)
- [Workload](workload.json)
- [Rights and provenance](RIGHTS.md)
- [Static inventory](check_inventory.py)

## Language ports

| Language | File |
|---|---|
| C | [galil_seiferas_search.c](../../../c/g/galil_seiferas_search.c) |
| C3 | [galil_seiferas_search.c3](../../../c3/g/galil_seiferas_search.c3) |
| C++ | [galil_seiferas_search.cpp](../../../cpp/g/galil_seiferas_search.cpp) |
| Elisa | [galil_seiferas_search.elisa](../../../elisa/g/galil_seiferas_search.elisa) |
| Mojo | [galil_seiferas_search.mojo](../../../mojo/g/galil_seiferas_search.mojo) |
| Nim | [galil_seiferas_search.nim](../../../nim/g/galil_seiferas_search.nim) |
| Odin | [galil_seiferas_search.odin](../../../odin/g/galil_seiferas_search.odin) |
| Rust | [galil_seiferas_search.rs](../../../rust/g/galil_seiferas_search.rs) |
| V | [galil_seiferas_search.v](../../../v/g/galil_seiferas_search.v) |
| Zig | [galil_seiferas_search.zig](../../../zig/g/galil_seiferas_search.zig) |

No programs, scripts, checkers, tests, builds, compilers, or benchmarks were run.
