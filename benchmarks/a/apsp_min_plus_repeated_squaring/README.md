# APSP by min-plus repeated squaring

This package implements the elementary min-plus repeated-squaring route to
all-pairs shortest distances described in Tadao Takaoka, “All Pairs Shortest
Paths via Matrix Multiplication,” *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_12`](https://doi.org/10.1007/978-1-4939-2864-4_12).
It uses the chapter's distance-matrix product
`C[i,j] = min_k(A[i,k] + B[k,j])` and repeatedly squares the distance matrix
until its represented path length covers a simple shortest path.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `apsp_min_plus_repeated_squaring`.
- Input is `[n,D[n*n]]`, where `D` is row-major and directed. Bounds are
  `1 <= n <= 8`. Diagonal entries must be zero; each off-diagonal entry is a
  positive integer edge cost in `1..1000` or `1_000_000` for no edge. Maximum
  input length is 65 signed-i64 words.
- Each min-plus square doubles the maximum represented edge count. The
  initial matrix covers paths of at most one edge; the profile squares until
  it covers at least `n-1` edges. Positive edge costs ensure an optimal path
  can be chosen simple, so this yields all-pairs shortest distances. Unreachable
  pairs retain the `1_000_000` sentinel.
- Output is the complete row-major `n*n` distance matrix as little-endian
  signed-i64 values. Maximum output is 512 bytes. Invalid input returns `-1`;
  a null output pointer or short capacity returns `-2` without writing.
- This is the elementary repeated-squaring algorithm, not the chapter's
  accelerated Alon–Galil–Margalit, Takaoka, or Zwick methods. It returns
  distances only; witness-matrix path reconstruction is outside the profile.

This algorithm is distinct from [`floyd_warshall`](../floyd_warshall/README.md),
which uses a middle-vertex relaxation recurrence, and from the single
[`min_plus_distance_product`](../min_plus_distance_product/README.md) operation.

## Source and rights

The source is the cited chapter's definition of the min-plus distance product
and its repeated-squaring APSP reduction. The ports are clean-room
implementations of that mathematical operation; no chapter prose, figures, or
code are copied, and no source-code license is asserted. See [`RIGHTS.md`](RIGHTS.md).

Fixtures are in [`workload.json`](workload.json). The primary oracle uses
repeated min-plus squaring; the independent verifier uses Floyd–Warshall:
[`apsp_min_plus_repeated_squaring_oracle.py`](../../apsp_min_plus_repeated_squaring_oracle.py)
and
[`apsp_min_plus_repeated_squaring_verifier_oracle.py`](../../apsp_min_plus_repeated_squaring_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/a/apsp_min_plus_repeated_squaring.c`](../../../c/a/apsp_min_plus_repeated_squaring.c) |
| C3 | [`c3/a/apsp_min_plus_repeated_squaring.c3`](../../../c3/a/apsp_min_plus_repeated_squaring.c3) |
| C++ | [`cpp/a/apsp_min_plus_repeated_squaring.cpp`](../../../cpp/a/apsp_min_plus_repeated_squaring.cpp) |
| Elisa | [`elisa/a/apsp_min_plus_repeated_squaring.elisa`](../../../elisa/a/apsp_min_plus_repeated_squaring.elisa) |
| Nim | [`nim/a/apsp_min_plus_repeated_squaring.nim`](../../../nim/a/apsp_min_plus_repeated_squaring.nim) |
| Odin | [`odin/a/apsp_min_plus_repeated_squaring.odin`](../../../odin/a/apsp_min_plus_repeated_squaring.odin) |
| Rust | [`rust/a/apsp_min_plus_repeated_squaring.rs`](../../../rust/a/apsp_min_plus_repeated_squaring.rs) |
| V | [`v/a/apsp_min_plus_repeated_squaring.v`](../../../v/a/apsp_min_plus_repeated_squaring.v) |
| Zig | [`zig/a/apsp_min_plus_repeated_squaring.zig`](../../../zig/a/apsp_min_plus_repeated_squaring.zig) |
