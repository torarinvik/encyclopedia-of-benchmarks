# NPB CG sparse outer product assembly

This package isolates the matrix-assembly kernel used to prepare the NAS
Parallel Benchmarks Conjugate Gradient (CG) matrix. Given a bounded list of
deterministic sparse vectors, it forms the geometric-weighted outer products,
adds the diagonal shift, accumulates repeated coordinates, and returns the
matrix in canonical compressed sparse column (CSC) order.

This fills a gap left by [`npb_cg_sparse_inverse_power`](../npb_cg_sparse_inverse_power/README.md),
which accepts an already assembled sparse matrix and measures its sparse
matrix-vector/CG/inverse-power work. This package stops at matrix assembly;
it does not run PRNG sampling, CG, or an inverse-power iteration.

## Bounded contract

The exported `npb_cg_sparse_outer_product_assembly` function uses the
`i64_array_bytes_output` ABI. Input is
`[n, nonzer, shift_micro, then n records of nonzer (coordinate,value_micro)
pairs]`. The matrix dimension is 2 through 16, `nonzer` is 1 through 4, and
each vector's supplied coordinates must be unique and in `[0,n)`. Values are
nonzero fixed-point micro-units in `[-1,000,000,1,000,000]`; shift is in
`[0,10,000,000]` micro-units.

For vector `i`, the profile inserts coordinate `i` with value `0.5` when it is
missing, or replaces its supplied value with `0.5`. It then forms
`w_i * x_i * x_i^T`, where `w_i = 0.1^(i/(n-1))` for `i=0..n-1`, and appends
`(0.1 - shift)I`. The report's endpoint schedule is pinned explicitly, so the
first and final weights are exactly 1 and 0.1. Coordinate collisions across
vectors are summed in vector generation order. Coordinates touched by a
contribution remain in the structure even if their sum is zero.

The output is a zero-based CSC matrix serialized as a contiguous
little-endian binary64 vector `[n, nnz, col_ptr[n+1], row_index[nnz],
values[nnz]]`. Structural fields are integral-valued doubles and exactly
representable under these bounds; columns ascend and row indices strictly
ascend within each column. Success returns the serialized byte count.
Malformed input returns `-1`; a null or undersized output buffer returns
`-2`. Input is validated before output capacity is considered. The suite
requires bit-exact agreement for the dimension, nonzero count, column pointers,
and row indices, then compares only matrix values with absolute and relative
tolerance `1e-12`.

The largest call has 416 raw contributions and a 4,248-byte output. The
workspace cap is 8,192 bytes. The primary reference builds and coalesces an
ordered COO contribution list. The independent reference accumulates directly
into a dense matrix and emits its touched coordinates in CSC order.

## Provenance

The algorithm is specified by D. Bailey et al., [*The NAS Parallel
Benchmarks*, NASA Ames Technical Report RNR-94-007](https://www.nas.nasa.gov/assets/nas/pdf/techreports/1994/rnr-94-007.pdf),
§2.2.3. The NPB 3.4.4 archive's `NPB3.4-MPI/CG/cg.f90` contains the related
`makea`, `vecset`, and `sparse` routines and serves as a behavioral cross-check.
The profile follows the report's stated endpoint weights. The source archive
uses `ratio=pow(0.1,1/n)` before generating `n` vectors, which makes its last
emitted weight `0.1^((n-1)/n)`; that implementation variant is not mixed into
this report-pinned profile.

See [`RIGHTS.md`](RIGHTS.md) for source-use notes and
[`workload.json`](workload.json) for machine-readable fixtures and bounds.

## Implementations

| Language | Source |
|---|---|
| C | [`c/n/npb_cg_sparse_outer_product_assembly.c`](../../../c/n/npb_cg_sparse_outer_product_assembly.c) |
| C3 | [`c3/n/npb_cg_sparse_outer_product_assembly.c3`](../../../c3/n/npb_cg_sparse_outer_product_assembly.c3) |
| C++ | [`cpp/n/npb_cg_sparse_outer_product_assembly.cpp`](../../../cpp/n/npb_cg_sparse_outer_product_assembly.cpp) |
| Elisa | [`elisa/n/npb_cg_sparse_outer_product_assembly.elisa`](../../../elisa/n/npb_cg_sparse_outer_product_assembly.elisa) |
| Mojo | [`mojo/n/npb_cg_sparse_outer_product_assembly.mojo`](../../../mojo/n/npb_cg_sparse_outer_product_assembly.mojo) |
| Nim | [`nim/n/npb_cg_sparse_outer_product_assembly.nim`](../../../nim/n/npb_cg_sparse_outer_product_assembly.nim) |
| Odin | [`odin/n/npb_cg_sparse_outer_product_assembly.odin`](../../../odin/n/npb_cg_sparse_outer_product_assembly.odin) |
| Rust | [`rust/n/npb_cg_sparse_outer_product_assembly.rs`](../../../rust/n/npb_cg_sparse_outer_product_assembly.rs) |
| V | [`v/n/npb_cg_sparse_outer_product_assembly.v`](../../../v/n/npb_cg_sparse_outer_product_assembly.v) |
| Zig | [`zig/n/npb_cg_sparse_outer_product_assembly.zig`](../../../zig/n/npb_cg_sparse_outer_product_assembly.zig) |
