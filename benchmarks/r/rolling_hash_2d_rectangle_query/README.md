# Two-dimensional rolling-hash rectangle queries

This benchmark builds a polynomial fingerprint table over an integer grid and
answers rectangle-hash queries by four-corner inclusion/exclusion. It is
distinct from [`rabin_karp`](../rabin_karp/README.md), which advances a
one-dimensional string window while searching for a pattern. It is also
distinct from the repository's
[`two_dimensional_scaled_pattern_matching`](../../t/two_dimensional_scaled_pattern_matching/README.md),
which performs exact cell-center sampling at a rational geometric scale.

## Contract

The `i64_array_bytes_output` symbol is
`rolling_hash_2d_rectangle_query(input, length, output, capacity) -> i64`.
Input is `[H,W,Q, grid(H*W row-major values), (r0,c0,r1,c1)*Q]`, with
`1 <= H,W <= 32`, `1 <= Q <= 128`, and cell values from 0 through 255. Each
rectangle is half-open, `[r0,r1) x [c0,c1)`, and must satisfy
`0 <= r0 <= r1 <= H` and `0 <= c0 <= c1 <= W`. Empty rectangles are valid and
hash to zero. The array must contain exactly `3 + H*W + 4*Q` signed-i64 words.

For each queried rectangle, the returned signed-i64 array contains its
normalized polynomial hash in query order:

`sum grid[i,j] * 31^(height-1-i) * 37^(width-1-j) mod 1,000,000,007`.

The row base is 31, the column base is 37, and the modulus is 1,000,000,007.
These parameters are fixed to make the profile deterministic; the result is a
fingerprint and can have polynomial-hash collisions. Each output value is
serialized as eight little-endian bytes. Success returns `8*Q`, malformed
input returns `-1`, and null output or insufficient capacity returns `-2`
without writing. Maximum output is 1,024 bytes and workspace metadata is
16,384 bytes.

The prefix table first rolls each row across columns and then extends those
row prefixes down the rows. A rectangle is extracted by combining four
prefixes, multiplying by the corresponding row or column powers, and
normalizing exponents to the rectangle's bottom and right edges. Preprocessing
takes `O(H*W)` time and space; each query takes `O(1)` time.

## References and verification

Nyaan's [Two-Dimensional Rolling Hash](https://nyaannyaan.github.io/library/string/rolling-hash-2d.hpp)
documents row and column powers, a two-dimensional prefix table, and constant
time four-corner rectangle extraction. The package uses only that algorithmic
idea and substitutes deterministic small bases and a single fixed prime.
[`primary_oracle.py`](primary_oracle.py) builds the two-dimensional prefix
table. [`independent_oracle.py`](independent_oracle.py) evaluates each query
directly as a weighted sum of its cells. `workload.json` includes full-grid,
overlapping, repeated, single-cell, one-row, and zero-area queries, plus
malformed inputs and output-buffer errors. [`RIGHTS.md`](RIGHTS.md) records
provenance, and [`verify_workload.py`](verify_workload.py) is a static package
inventory module; it has not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/rolling_hash_2d_rectangle_query.c`](../../../c/r/rolling_hash_2d_rectangle_query.c) |
| C3 | [`c3/r/rolling_hash_2d_rectangle_query.c3`](../../../c3/r/rolling_hash_2d_rectangle_query.c3) |
| C++ | [`cpp/r/rolling_hash_2d_rectangle_query.cpp`](../../../cpp/r/rolling_hash_2d_rectangle_query.cpp) |
| Elisa | [`elisa/r/rolling_hash_2d_rectangle_query.elisa`](../../../elisa/r/rolling_hash_2d_rectangle_query.elisa) |
| Mojo | [`mojo/r/rolling_hash_2d_rectangle_query.mojo`](../../../mojo/r/rolling_hash_2d_rectangle_query.mojo) |
| Nim | [`nim/r/rolling_hash_2d_rectangle_query.nim`](../../../nim/r/rolling_hash_2d_rectangle_query.nim) |
| Odin | [`odin/r/rolling_hash_2d_rectangle_query.odin`](../../../odin/r/rolling_hash_2d_rectangle_query.odin) |
| Rust | [`rust/r/rolling_hash_2d_rectangle_query.rs`](../../../rust/r/rolling_hash_2d_rectangle_query.rs) |
| V | [`v/r/rolling_hash_2d_rectangle_query.v`](../../../v/r/rolling_hash_2d_rectangle_query.v) |
| Zig | [`zig/r/rolling_hash_2d_rectangle_query.zig`](../../../zig/r/rolling_hash_2d_rectangle_query.zig) |

The `i64_array_bytes_output` runner and verifier register the
`rolling_hash_2d_rectangle_query` symbol.
