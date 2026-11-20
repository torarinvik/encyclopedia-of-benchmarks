# Apostolico-Crochemore string search

Input is `[n,m,text...,pattern...]`, where the text has at most 4,096 symbols,
the pattern has 1..128 symbols, and each symbol is in `0..3`. Return a packed
summary of every overlapping match start: `(count << 36) | (sum_offsets <<
12) | xor_offsets`. The field widths cover every possible result in this
bounded domain. Invalid input returns `-1`.

The primary computes the KMP-next shift table and the pattern's initial run
length `ell`. Its search state tracks `(i,j,k)`: the current pattern position,
text alignment, and prefix comparison length. It compares from `ell` onward,
then verifies the initial run, and updates the remembered prefix and next
alignment using the KMP-next table. Preprocessing and search take `O(m+n)` time.
The shift table uses `O(m)` space; ports that copy the text into bounded local
storage use `O(n+m)` total scratch. The independent reference checks every
alignment directly.

This is distinct from KMP, Boyer-Moore, and Crochemore-Perrin Two-Way search;
the Apostolico-Crochemore search combines a critical prefix length with KMP-next
shifts and reuses comparison state across alignments.

The algorithm description is available from [Lecroq's string matching
reference](https://www-igm.univ-mlv.fr/~lecroq/string/node12.html); the listed
paper is Apostolico and Crochemore, *Optimal canonization of all substrings of
a string* (1991). The package is clean-room; see [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/a/apostolico_crochemore_search.c](../../../c/a/apostolico_crochemore_search.c) |
| C3 | [c3/a/apostolico_crochemore_search.c3](../../../c3/a/apostolico_crochemore_search.c3) |
| C++ | [cpp/a/apostolico_crochemore_search.cpp](../../../cpp/a/apostolico_crochemore_search.cpp) |
| Elisa | [elisa/a/apostolico_crochemore_search.elisa](../../../elisa/a/apostolico_crochemore_search.elisa) |
| Mojo | [mojo/a/apostolico_crochemore_search.mojo](../../../mojo/a/apostolico_crochemore_search.mojo) |
| Nim | [nim/a/apostolico_crochemore_search.nim](../../../nim/a/apostolico_crochemore_search.nim) |
| Odin | [odin/a/apostolico_crochemore_search.odin](../../../odin/a/apostolico_crochemore_search.odin) |
| Rust | [rust/a/apostolico_crochemore_search.rs](../../../rust/a/apostolico_crochemore_search.rs) |
| V | [v/a/apostolico_crochemore_search.v](../../../v/a/apostolico_crochemore_search.v) |
| Zig | [zig/a/apostolico_crochemore_search.zig](../../../zig/a/apostolico_crochemore_search.zig) |
