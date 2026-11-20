# String Matching on Ordered Alphabets

Input is `[n,m,text...,pattern...]`, with `0<=n<=4096`, `1<=m<=128`, and
symbols in the ordered alphabet `0..3`. The scalar result packs all possibly
overlapping match offsets as `(count<<36)|(sum<<12)|xor`; malformed input
returns `-1`.

The search has no pattern-preprocessing phase and uses constant auxiliary
space. It compares the pattern with the current text window, then updates a
maximal-suffix decomposition and period state from the matched text prefix
plus its mismatch symbol. The resulting shift either retains a known prefix
under the period or discards it and resets the state. The ordering of symbols
is essential to the maximal-suffix update. The published profile has `O(n)`
search time and at most `6n+5` text-character comparisons.

The primary reference implements this online maximal-suffix update. The
independent reference checks every legal alignment directly. This differs
from [`crochemore_perrin_two_way`](../../c/crochemore_perrin_two_way/README.md),
which preprocesses a critical factorization of the pattern and uses its period
memory. Here the evolving decomposition comes from the text being searched,
with no pattern preprocessing. The method follows the
[official description](https://igm.univ-mlv.fr/~lecroq/string/node27.html) and
Crochemore's 1992 paper. Only algorithm ideas were consulted; code, contract,
documentation, and fixtures were independently authored. See
[RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/s/string_matching_ordered_alphabets.c](../../../c/s/string_matching_ordered_alphabets.c) |
| C3 | [c3/s/string_matching_ordered_alphabets.c3](../../../c3/s/string_matching_ordered_alphabets.c3) |
| C++ | [cpp/s/string_matching_ordered_alphabets.cpp](../../../cpp/s/string_matching_ordered_alphabets.cpp) |
| Elisa | [elisa/s/string_matching_ordered_alphabets.elisa](../../../elisa/s/string_matching_ordered_alphabets.elisa) |
| Mojo | [mojo/s/string_matching_ordered_alphabets.mojo](../../../mojo/s/string_matching_ordered_alphabets.mojo) |
| Nim | [nim/s/string_matching_ordered_alphabets.nim](../../../nim/s/string_matching_ordered_alphabets.nim) |
| Odin | [odin/s/string_matching_ordered_alphabets.odin](../../../odin/s/string_matching_ordered_alphabets.odin) |
| Rust | [rust/s/string_matching_ordered_alphabets.rs](../../../rust/s/string_matching_ordered_alphabets.rs) |
| V | [v/s/string_matching_ordered_alphabets.v](../../../v/s/string_matching_ordered_alphabets.v) |
| Zig | [zig/s/string_matching_ordered_alphabets.zig](../../../zig/s/string_matching_ordered_alphabets.zig) |
