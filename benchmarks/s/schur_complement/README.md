# Schur complement

Compute a scalar Schur complement from a small symmetric block matrix. This
package follows the `schur_complement(mat_a, mat_b, mat_c, pseudo_inv=None)`
function in the pinned
[TheAlgorithms/Python `schur_complement.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/src/schur_complement.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`.

## Contract

The `i64_array_float64` input is
`[a00, a01, a11, b0, b1, c00]`, with exactly six signed 64-bit integers. They
form the symmetric matrices

```text
A = [[a00, a01], [a01, a11]]
B = [[b0], [b1]]
C = [[c00]]
```

Each A entry is in `[-8, 8]`; A must be nonsingular. Each B and C entry is in
`[-100, 100]`. The source is called with its default `pseudo_inv=None`, so it
computes `C - B.T @ inv(A) @ B`. Since C is 1×1 here, the benchmark returns
the sole result element as binary64. Preserve the source's matrix operation
order. Invalid input returns the finite sentinel `-1e300`; the result is
checked with absolute tolerance `1e-8` and relative tolerance `1e-12` to allow
for small inverse-rounding differences in the high-magnitude cancellation case.

[`workload.json`](workload.json) covers identity, diagonal, and off-diagonal
invertible A matrices, zero and bounded B values, a negative Schur result,
a high-magnitude cancellation case, singular A, malformed lengths, and
out-of-range entries. The independent
oracle is
[`benchmarks/schur_complement_oracle.py`](../../schur_complement_oracle.py).

Build and record the Rust port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm schur_complement --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/s/schur_complement/rust/build.json
python3 benchmarks/verify_i64_array_float64.py --algorithm schur_complement --languages rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/schur_complement.c`](../../../c/s/schur_complement.c) |
| C3 | [`c3/s/schur_complement.c3`](../../../c3/s/schur_complement.c3) |
| C++ | [`cpp/s/schur_complement.cpp`](../../../cpp/s/schur_complement.cpp) |
| Elisa | [`elisa/s/schur_complement.elisa`](../../../elisa/s/schur_complement.elisa) |
| Nim | [`nim/s/schur_complement.nim`](../../../nim/s/schur_complement.nim) |
| Odin | [`odin/s/schur_complement.odin`](../../../odin/s/schur_complement.odin) |
| Rust | [`rust/s/schur_complement.rs`](../../../rust/s/schur_complement.rs) |
| V | [`v/s/schur_complement.v`](../../../v/s/schur_complement.v) |
| Zig | [`zig/s/schur_complement.zig`](../../../zig/s/schur_complement.zig) |
