# SMAWK row minima

This package returns the leftmost minimum column of every row in an explicitly
supplied totally monotone matrix. SMAWK reduces candidate columns, recursively
solves the odd-numbered rows, and interpolates minima for the remaining rows.
The matrix is an input promise: for every two rows `i<k` and columns `j<l`,
`A[i,j] > A[i,l]` implies `A[k,j] > A[k,l]`. This prevents a two-column
submatrix's leftmost minimum from moving left as the row index increases, and
is the row-minimum form of total monotonicity.

## Contract

The `i64_array_bytes_output` symbol is
`smawk_row_minima(input, length, output, capacity) -> i64`. Input is
`[row_count, column_count, row_major_matrix...]`; each dimension is in
`1..=16`, the frame contains exactly `2 + row_count*column_count` signed
64-bit entries, and matrix values may be any signed 64-bit integers. Invalid
framing or dimensions return `-1` before output checks.

The output is one zero-based leftmost minimum column index per row, in row
order, encoded as little-endian signed 64-bit integers. A null output pointer
or insufficient capacity returns `-2` without writes. Maximum output is 128 bytes; workspace is
4,096 bytes, including bounded reduction/interpolation scratch and staged
output. Input is promised to be totally monotone; the ports do not scan the
matrix to verify that promise.

For `n` rows and `m` columns, SMAWK performs `O(n+m)` matrix comparisons and
uses bounded scratch within the stated profile. Reading the packed matrix is
not part of its comparison count.

## Distinction and verification

[`min_plus_convolution_convex_arbitrary`](../../m/min_plus_convolution_convex_arbitrary/README.md)
uses monotone divide-and-conquer minima for one convolution-specific Monge
matrix. SMAWK is a different, general row-minima algorithm that performs
column reduction, odd-row recursion, and interpolation; it does not rely on a
convolution recurrence or monotone search bounds supplied from neighboring
rows.

The [primary oracle](primary_oracle.py) implements SMAWK. The
[independent oracle](independent_oracle.py) scans every matrix row directly
and applies the leftmost tie rule. The [workload](workload.json) includes
single-row, rectangular, tied-minimum, and malformed/capacity cases.

## Provenance

The algorithm is from Aggarwal, Klawe, Moran, Shor, and Wilber, “Geometric
applications of a matrix-searching algorithm,” *Algorithmica* 2, 1987,
[DOI 10.1007/BF01840359](https://doi.org/10.1007/BF01840359). Only the
algorithm description was used; see [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/smawk_row_minima.c`](../../../c/s/smawk_row_minima.c) |
| C3 | [`c3/s/smawk_row_minima.c3`](../../../c3/s/smawk_row_minima.c3) |
| C++ | [`cpp/s/smawk_row_minima.cpp`](../../../cpp/s/smawk_row_minima.cpp) |
| Elisa | [`elisa/s/smawk_row_minima.elisa`](../../../elisa/s/smawk_row_minima.elisa) |
| Mojo | [`mojo/s/smawk_row_minima.mojo`](../../../mojo/s/smawk_row_minima.mojo) |
| Nim | [`nim/s/smawk_row_minima.nim`](../../../nim/s/smawk_row_minima.nim) |
| Odin | [`odin/s/smawk_row_minima.odin`](../../../odin/s/smawk_row_minima.odin) |
| Rust | [`rust/s/smawk_row_minima.rs`](../../../rust/s/smawk_row_minima.rs) |
| V | [`v/s/smawk_row_minima.v`](../../../v/s/smawk_row_minima.v) |
| Zig | [`zig/s/smawk_row_minima.zig`](../../../zig/s/smawk_row_minima.zig) |
