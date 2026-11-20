# Skip Search

Input is `[n,m,text...,pattern...]`, with `0<=n<=4096`, `1<=m<=128`,
and symbols in `0..3`. The scalar result packs the count, sum, and xor of all
possibly overlapping match offsets as `(count<<36)|(sum<<12)|xor`.
Malformed input returns `-1`.

Preprocessing places every pattern position into a bucket for its symbol. The
search samples text positions `m-1, 2m-1, 3m-1, ...`. For each sampled symbol,
its bucket positions propose starts `sample-position`; the algorithm verifies
each in-range candidate against the whole pattern. Every length-`m` occurrence
contains exactly one sampled position, so all matches are found once. Empty
buckets naturally skip sampled symbols that do not occur in the pattern.

Preprocessing takes `O(m+sigma)` time and space for alphabet size `sigma=4`.
The search uses `O(mn)` worst-case time and `O(n)` expected character
inspections under a uniform symbol model. Ports that copy the input use
`O(n+m+sigma)` auxiliary space. The method follows the
[Skip Search description](https://igm.univ-mlv.fr/~lecroq/string/node31.html).

This profile buckets every single pattern position and samples at stride `m`.
[`alpha_skip_search`](../../a/alpha_skip_search/README.md) instead buckets
fixed-length factors and samples at stride `m-ell+1`; [`kmp_skip_search`](../../k/kmp_skip_search/README.md)
combines character buckets with MP/KMP border-shift processing. The primary
reference implements the bucket-and-sample method; the independent reference
checks every legal alignment directly. Only the published algorithm idea was
consulted. The code, contract, documentation, and fixtures are independently
authored; see [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [c/s/skip_search.c](../../../c/s/skip_search.c) |
| C3 | [c3/s/skip_search.c3](../../../c3/s/skip_search.c3) |
| C++ | [cpp/s/skip_search.cpp](../../../cpp/s/skip_search.cpp) |
| Elisa | [elisa/s/skip_search.elisa](../../../elisa/s/skip_search.elisa) |
| Mojo | [mojo/s/skip_search.mojo](../../../mojo/s/skip_search.mojo) |
| Nim | [nim/s/skip_search.nim](../../../nim/s/skip_search.nim) |
| Odin | [odin/s/skip_search.odin](../../../odin/s/skip_search.odin) |
| Rust | [rust/s/skip_search.rs](../../../rust/s/skip_search.rs) |
| V | [v/s/skip_search.v](../../../v/s/skip_search.v) |
| Zig | [zig/s/skip_search.zig](../../../zig/s/skip_search.zig) |
