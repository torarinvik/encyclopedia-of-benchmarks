# Reverse Colussi Search

Input is `[n,m,text...,pattern...]`, with `0<=n<=4096`, `1<=m<=128`, and
symbols in `0..3`. The scalar result packs every possibly overlapping match
offset as `(count<<36)|(sum<<12)|xor`; malformed input returns `-1`.

Reverse Colussi is a Boyer–Moore refinement. It first checks the final pattern
symbol, then compares the remaining positions in a pattern-specific order
`h`. The preprocessing builds an alphabet-by-shift bad-character table and a
good-suffix shift sequence `rcGs`. The comparison order and shifts are built
together from the pattern's periodic suffix structure. This differs from
ordinary Boyer–Moore's right-to-left order, Colussi's forward no-hole order,
KmpSkip's bucket/wall scan, and Alpha Skip's sampled factor buckets.

For alphabet size `sigma=4`, this bounded direct table construction takes
`O(sigma*m^2)` time and `O(sigma*m)` auxiliary space. Search uses `O(n)` time
and at most `2n` text-character comparisons. The ports use a bounded text
copy in addition to their tables.

The algorithm follows Lecroq's [Reverse Colussi description](https://igm.univ-mlv.fr/~lecroq/string/node17.html),
which cites Colussi's 1994 paper, “Fastest pattern matching in strings.” Only
the algorithm idea was consulted; the benchmark code, contract, fixtures,
and documentation are independently authored. Provenance is recorded in
[RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/r/reverse_colussi_search.c](../../../c/r/reverse_colussi_search.c) |
| C3 | [c3/r/reverse_colussi_search.c3](../../../c3/r/reverse_colussi_search.c3) |
| C++ | [cpp/r/reverse_colussi_search.cpp](../../../cpp/r/reverse_colussi_search.cpp) |
| Elisa | [elisa/r/reverse_colussi_search.elisa](../../../elisa/r/reverse_colussi_search.elisa) |
| Mojo | [mojo/r/reverse_colussi_search.mojo](../../../mojo/r/reverse_colussi_search.mojo) |
| Nim | [nim/r/reverse_colussi_search.nim](../../../nim/r/reverse_colussi_search.nim) |
| Odin | [odin/r/reverse_colussi_search.odin](../../../odin/r/reverse_colussi_search.odin) |
| Rust | [rust/r/reverse_colussi_search.rs](../../../rust/r/reverse_colussi_search.rs) |
| V | [v/r/reverse_colussi_search.v](../../../v/r/reverse_colussi_search.v) |
| Zig | [zig/r/reverse_colussi_search.zig](../../../zig/r/reverse_colussi_search.zig) |
