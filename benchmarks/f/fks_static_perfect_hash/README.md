# FKS static perfect hashing

This package builds a two-level static perfect hash table on every call, then
answers up to eight membership queries. It implements the Fredman–Komlós–
Szemerédi (FKS) construction with a fixed, deterministic seed order so every
port constructs the same table.

## Contract

The ABI is `i64_array_scalar` and the exported symbol is
`fks_static_perfect_hash`. Input is `[n, q, keys..., queries...]`, with
`0<=n,q<=8`, exactly `2+n+q` signed 64-bit values, all keys and queries in
`0..255`, and distinct stored keys. Queries may repeat. Null input, malformed
framing, out-of-range values, or duplicate stored keys return `-1`.

The result is a bit mask: bit `i` is one exactly when query `i` occurs in the
stored key set. Thus the result is between 0 and 255; an empty query list
returns zero. The table is rebuilt even when `q=0`.

## Deterministic FKS profile

The prime is `p=257`, and a seed `(a,b)` hashes key `x` into `m` cells as
`((a*x+b) mod 257) mod m`. Seeds are tried in lexicographic order: `a` from
1 through 256, then `b` from 0 through 256. The first-level table has `n`
buckets; the empty-set case skips it. The first seed with
`sum(bucket_size^2)<=4*n` is selected. Each nonempty bucket of size `k` gets
`k^2` cells and the first seed in the same order that places its keys without
collisions.

The logical FKS table has at most 32 second-level cells by the first-level
bound; ports reserve fixed-size buffers for the maximum eight-key input. For
`n<=8`, the bounded deterministic search uses at most `O(p^2*n^2)` simple
bucket checks across both levels and `O(n)` stored cells. Each query performs
two hash computations and one key comparison. The per-key equality check makes
the output exact, not a fingerprint estimate.

The primary oracle constructs the same deterministic FKS table. The independent
oracle builds a plain set and computes the membership mask by direct lookup;
it does not reproduce FKS hashing.

## Sources and ports

The algorithm follows Fredman, Komlós, and Szemerédi, “Storing a Sparse Table
with O(1) Worst Case Access Time,” *Journal of the ACM* 31(3), 1984,
[DOI 10.1145/828.1884](https://doi.org/10.1145/828.1884). A freely available
[lecture note on the FKS perfect-hashing scheme](https://theory.stanford.edu/~matias/papers/fks.pdf)
describes the two-level bucket and squared-bucket-size construction. Only the
algorithmic method was used; no source code or prose was copied. See
[RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/f/fks_static_perfect_hash.c`](../../../c/f/fks_static_perfect_hash.c) |
| C3 | [`c3/f/fks_static_perfect_hash.c3`](../../../c3/f/fks_static_perfect_hash.c3) |
| C++ | [`cpp/f/fks_static_perfect_hash.cpp`](../../../cpp/f/fks_static_perfect_hash.cpp) |
| Elisa | [`elisa/f/fks_static_perfect_hash.elisa`](../../../elisa/f/fks_static_perfect_hash.elisa) |
| Mojo | [`mojo/f/fks_static_perfect_hash.mojo`](../../../mojo/f/fks_static_perfect_hash.mojo) |
| Nim | [`nim/f/fks_static_perfect_hash.nim`](../../../nim/f/fks_static_perfect_hash.nim) |
| Odin | [`odin/f/fks_static_perfect_hash.odin`](../../../odin/f/fks_static_perfect_hash.odin) |
| Rust | [`rust/f/fks_static_perfect_hash.rs`](../../../rust/f/fks_static_perfect_hash.rs) |
| V | [`v/f/fks_static_perfect_hash.v`](../../../v/f/fks_static_perfect_hash.v) |
| Zig | [`zig/f/fks_static_perfect_hash.zig`](../../../zig/f/fks_static_perfect_hash.zig) |

The bounded [workload](workload.json) includes hits, misses, a shared
first-level bucket that exercises local hashing, empty sets, maximum-size
inputs, invalid frames, and null input. [`verify_workload.py`](verify_workload.py)
contains a static inventory and reference-fixture review.
