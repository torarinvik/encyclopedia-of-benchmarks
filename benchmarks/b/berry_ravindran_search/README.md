# Berry–Ravindran exact string search

This clean-room profile implements Berry–Ravindran’s exact matcher. It
compares each candidate window left to right and shifts using the ordered
pair of text symbols immediately to the right of that window. Its shift table
is indexed by both symbols, unlike Quick Search’s one-symbol lookahead. It is
also distinct from Zhu–Takaoka’s pair-based mismatch shift: this profile reads
the pair after the whole current window.

## Contract

- ABI: i64_array_scalar; symbol: berry_ravindran_search.
- Input: [text_length, pattern_length, text_bytes..., pattern_bytes...].
- Text length is 0..256; pattern length is 1..16; bytes are 0..15.
- The input must contain exactly 2 + text_length + pattern_length values.
- Return the first matching zero-based offset, -1 when absent, or -2 for
  null input, malformed framing, out-of-range lengths, or invalid bytes.
- Maximum valid and parseable frame length: 274 signed 64-bit values.

Let m be the pattern length. The pair shift table starts at m+2; every
pair ending in the pattern’s first symbol gets shift m+1; each adjacent
pattern pair at offset i gets m-i; and every pair starting with the final
pattern symbol gets shift 1. These assignments implement the rightmost
occurrence rule, with later/smaller shifts taking precedence. Search reads
text[start+m] and text[start+m+1] after a failed window. A distinct virtual
sentinel value 16 stands for a missing second lookahead byte; when even the
first byte is missing, the current window is the final possible alignment and
the search ends. Thus embedded zero bytes remain ordinary alphabet symbols.

The alphabet size is fixed at 16, so preprocessing uses a 17-by-17 table in
O(m+σ²) time and space; candidate comparisons give O(mn) worst-case search.
The direct-window reference uses no table or shifts.

## Sources

- [Charras–Lecroq: Berry–Ravindran algorithm](https://igm.univ-mlv.fr/~lecroq/string/berryravindran.html)
- Berry, T. and Ravindran, S. (1999), “A fast string matching algorithm and experimental results,” Prague Stringology Club Workshop’99, Collaborative Report DC-99-05, pp. 16–26.

These sources provide the algorithm description and provenance only. The
implementations and test inputs are newly written; no source code or example
text is copied.

## Package files

- [Shift-table primary reference](primary_oracle.py)
- [Independent direct-window reference](independent_oracle.py)
- [Workload](workload.json)
- [Rights and provenance](RIGHTS.md)
- [Static inventory](check_inventory.py)

## Language ports

| Language | File |
|---|---|
| C | [berry_ravindran_search.c](../../../c/b/berry_ravindran_search.c) |
| C3 | [berry_ravindran_search.c3](../../../c3/b/berry_ravindran_search.c3) |
| C++ | [berry_ravindran_search.cpp](../../../cpp/b/berry_ravindran_search.cpp) |
| Elisa | [berry_ravindran_search.elisa](../../../elisa/b/berry_ravindran_search.elisa) |
| Mojo | [berry_ravindran_search.mojo](../../../mojo/b/berry_ravindran_search.mojo) |
| Nim | [berry_ravindran_search.nim](../../../nim/b/berry_ravindran_search.nim) |
| Odin | [berry_ravindran_search.odin](../../../odin/b/berry_ravindran_search.odin) |
| Rust | [berry_ravindran_search.rs](../../../rust/b/berry_ravindran_search.rs) |
| V | [berry_ravindran_search.v](../../../v/b/berry_ravindran_search.v) |
| Zig | [berry_ravindran_search.zig](../../../zig/b/berry_ravindran_search.zig) |

No programs, scripts, checkers, tests, builds, compilers, or benchmarks were run.
