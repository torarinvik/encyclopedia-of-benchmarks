# Alpha Skip Search

Input is `[n,m,text...,pattern...]`, with a four-symbol alphabet `0..3`,
`0<=n<=4096`, and `1<=m<=128`. The result packs the count, sum, and xor of
all possibly overlapping match offsets as `(count<<36)|(sum<<12)|xor`.
Malformed input returns `-1`.

The search chooses a fixed factor length `ell=max(1,floor(log_4(m)))` and
stores every pattern factor of that length in a bucket indexed by its base-4
code. It samples text factors every `m-ell+1` symbols, uses the matching
bucket to generate candidate alignments, and verifies each candidate against
the full pattern. The sample spacing guarantees that every true occurrence
contains one sampled factor. The independent reference checks every possible
alignment directly.

Factor codes are updated as a rolling base-4 window, so pattern preprocessing
takes `O(m+4^ell)` time and space. The search is `O(m*n)` in the worst case;
for a uniform small alphabet it examines about
`O(ell*n/(m-ell+1))` factor comparisons on average. Total scratch space is
`O(n+m+4^ell)` in ports that copy the text. This is distinct from
[`knuth_morris_pratt`](../../k/knuth_morris_pratt/README.md), which uses
prefix-failure shifts rather than sampled factor buckets, and from
[`crochemore_perrin_two_way`](../../c/crochemore_perrin_two_way/README.md),
which uses critical factorization and period-memory shifts.

The algorithm follows Charras, Lecroq, and Pehoushek's [Alpha Skip Search
description](https://igm.univ-mlv.fr/~lecroq/string/node33.html) and their 1998
paper. The contract deliberately uses the ordinary floor convention for
`log_4(m)`; at exact powers of four, Lecroq's published integer loop selects a
factor one symbol shorter. The shift is derived from the selected factor
length, so both choices retain the sampled-residue coverage proof. Only the
algorithm description was consulted; the code, contract, and fixtures are
independently authored.

| Language | Port |
|---|---|
| C | [c/a/alpha_skip_search.c](../../../c/a/alpha_skip_search.c) |
| C3 | [c3/a/alpha_skip_search.c3](../../../c3/a/alpha_skip_search.c3) |
| C++ | [cpp/a/alpha_skip_search.cpp](../../../cpp/a/alpha_skip_search.cpp) |
| Elisa | [elisa/a/alpha_skip_search.elisa](../../../elisa/a/alpha_skip_search.elisa) |
| Mojo | [mojo/a/alpha_skip_search.mojo](../../../mojo/a/alpha_skip_search.mojo) |
| Nim | [nim/a/alpha_skip_search.nim](../../../nim/a/alpha_skip_search.nim) |
| Odin | [odin/a/alpha_skip_search.odin](../../../odin/a/alpha_skip_search.odin) |
| Rust | [rust/a/alpha_skip_search.rs](../../../rust/a/alpha_skip_search.rs) |
| V | [v/a/alpha_skip_search.v](../../../v/a/alpha_skip_search.v) |
| Zig | [zig/a/alpha_skip_search.zig](../../../zig/a/alpha_skip_search.zig) |
