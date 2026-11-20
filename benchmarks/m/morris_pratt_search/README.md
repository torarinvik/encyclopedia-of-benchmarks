# Morris–Pratt Search

Input is `[n,m,text...,pattern...]`, with `0<=n<=4096`, `1<=m<=128`, and
symbols in the ordered alphabet `0..3`. The scalar result packs all
possibly overlapping match offsets as `(count<<36)|(sum<<12)|xor`;
malformed input returns `-1`.

Preprocessing builds `mpNext[i]`, the length of the longest proper border of
the first `i` pattern symbols, with `mpNext[0] = -1`. During the left-to-right
scan, a mismatch follows these ordinary border links, and a full match follows
the same table to retain overlap. The method takes `O(m)` preprocessing time
and space and `O(n+m)` total time; for nonempty text, the published analysis
bounds text-symbol comparisons by `2n-1` (empty text performs none).

This is the original Morris–Pratt fallback. Local
[`knuth_morris_pratt`](../../k/knuth_morris_pratt/README.md) and
[`kmp_all_occurrences`](../../k/kmp_all_occurrences/README.md) use KMP-style
prefix fallback; the optimized KMP table stores tagged borders and can skip a
fallback whose next pattern symbol would immediately mismatch. This package
retains the longest border without that KMP optimization. Its primary reference
uses the `mpNext` border table, while the independent reference tests every
alignment directly. The algorithm follows the
[Morris–Pratt description](https://www-igm.univ-mlv.fr/~lecroq/string/node7.html);
only the algorithm idea was consulted. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/m/morris_pratt_search.c](../../../c/m/morris_pratt_search.c) |
| C3 | [c3/m/morris_pratt_search.c3](../../../c3/m/morris_pratt_search.c3) |
| C++ | [cpp/m/morris_pratt_search.cpp](../../../cpp/m/morris_pratt_search.cpp) |
| Elisa | [elisa/m/morris_pratt_search.elisa](../../../elisa/m/morris_pratt_search.elisa) |
| Mojo | [mojo/m/morris_pratt_search.mojo](../../../mojo/m/morris_pratt_search.mojo) |
| Nim | [nim/m/morris_pratt_search.nim](../../../nim/m/morris_pratt_search.nim) |
| Odin | [odin/m/morris_pratt_search.odin](../../../odin/m/morris_pratt_search.odin) |
| Rust | [rust/m/morris_pratt_search.rs](../../../rust/m/morris_pratt_search.rs) |
| V | [v/m/morris_pratt_search.v](../../../v/m/morris_pratt_search.v) |
| Zig | [zig/m/morris_pratt_search.zig](../../../zig/m/morris_pratt_search.zig) |
