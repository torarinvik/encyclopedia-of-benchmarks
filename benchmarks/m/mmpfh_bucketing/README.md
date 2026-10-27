# Monotone minimal perfect hashing by equal-size buckets

This bounded profile follows the equal-size bucketing construction in
*Monotone Minimal Perfect Hash Functions*, Encyclopedia of Algorithms, DOI
10.1007/978-1-4939-2864-4_639. It accepts a sorted set of fixed-width bit-vector
keys, partitions it into buckets of three, computes each bucket's longest
common-prefix delimiter, and builds the explicit `d0` (key to delimiter
length) and `d1` (delimiter prefix to bucket) maps. A query's local ordinal
within its bucket gives its global monotone rank.

The input is `[n, q, key_0, ..., key_(n-1), query_0, ..., query_(q-1)]`.
`1 <= n,q <= 32`; keys and queries are unsigned 16-bit integers represented
as nonnegative `i64` values. Keys must be strictly increasing, and every query
must be a member of the set. The final bucket may have one or two keys. Query
order is preserved.

The `i64_array_bytes_output` result is a little-endian signed-64 word vector:

`[n, bucket_count, q, d0(key_0)..d0(key_(n-1)), (prefix_length,prefix_value,bucket_id)*, rank_0..rank_(q-1)]`

The largest output has `3 + 32 + 3*11 + 32 = 100` words (800 bytes). Invalid
framing, out-of-range keys, unsorted or duplicate keys, and absent queries
return `-1`; a null output or capacity below the actual staged result size
returns `-2` without writing output.

This package exposes the chapter's distributor structure and local ordinal
mapping using explicit tables. It does not implement succinct `d0`, `d1`, or
bucket functions, hash-function selection, probabilistic construction, or any
of the chapter's space/time tradeoff encodings. No succinct-space or
constant-time claim is made.

The primary oracle constructs the bucket delimiters and evaluates queries
through the `d0`/`d1` maps. The verifier oracle independently forms groups and
their common bit prefixes, then resolves each query from those tables.

Source: Boldi and Vigna, “Monotone Minimal Perfect Hash Functions,” in
*Encyclopedia of Algorithms*, DOI 10.1007/978-1-4939-2864-4_639. See
[`RIGHTS.md`](RIGHTS.md) for scope and attribution.
