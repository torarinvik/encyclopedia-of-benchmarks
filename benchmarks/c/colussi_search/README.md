# Colussi string search

Input is `[n,m,text...,pattern...]`, with a four-symbol alphabet `0..3`,
`0<=n<=4096`, and `1<=m<=128`. The result packs the count, sum, and xor of
all possibly overlapping match offsets as `(count<<36)|(sum<<12)|xor`.
Malformed input returns `-1`.

Preprocessing divides pattern positions into noholes and holes. Each search
attempt compares noholes in increasing order, then holes in decreasing order.
The tables carry safe shifts and the next comparison position, while `last`
remembers a text prefix already known to match. This gives linear preprocessing
and search time, with at most `3n/2` text comparisons. The independent oracle
checks every alignment directly.

This is related to the local KMP and Apostolico–Crochemore profiles, but uses
Colussi's two-part comparison ordering and `h`/`next`/`shift` tables to reduce
the worst-case number of text comparisons. It differs from Alpha Skip Search,
which samples fixed-length factors into alphabet buckets.

The algorithm follows the [Colussi description by Lecroq](https://igm.univ-mlv.fr/~lecroq/string/node10.html)
and the 1990 paper by Colussi, Galil, and Giancarlo. Only algorithm ideas were
consulted; the local contract, implementation, fixtures, and direct oracle are
independently authored.

| Language | Port |
|---|---|
| C | [c/c/colussi_search.c](../../../c/c/colussi_search.c) |
| C3 | [c3/c/colussi_search.c3](../../../c3/c/colussi_search.c3) |
| C++ | [cpp/c/colussi_search.cpp](../../../cpp/c/colussi_search.cpp) |
| Elisa | [elisa/c/colussi_search.elisa](../../../elisa/c/colussi_search.elisa) |
| Mojo | [mojo/c/colussi_search.mojo](../../../mojo/c/colussi_search.mojo) |
| Nim | [nim/c/colussi_search.nim](../../../nim/c/colussi_search.nim) |
| Odin | [odin/c/colussi_search.odin](../../../odin/c/colussi_search.odin) |
| Rust | [rust/c/colussi_search.rs](../../../rust/c/colussi_search.rs) |
| V | [v/c/colussi_search.v](../../../v/c/colussi_search.v) |
| Zig | [zig/c/colussi_search.zig](../../../zig/c/colussi_search.zig) |
