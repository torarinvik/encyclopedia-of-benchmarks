# Cholesky decomposition

This package ports the pinned Python Cholesky decomposition routine. It performs the lower-triangle recurrence and emits the full `n × n` factor `L`, including zeros above the diagonal, such that `A = L Lᵀ`.

## Contract

- Input is `[n, matrix entries...]`, with `n` from 1 through 6 and exactly `n*n` row-major entries after the dimension. Each signed integer entry is divided by 1,000,000 to obtain its binary64 matrix value; scaled entries are bounded to ±1,000,000,000 (matrix values ±1,000).
- The source checks symmetry with NumPy's default `allclose` tolerance: `abs(a-b) <= 1e-8 + 1e-5*abs(b)`, including the transposed comparison. For accepted near-symmetric input, the factorization reads the lower triangle, matching the source's `np.tril` copy.
- Every diagonal pivot must be strictly positive. Malformed shape/range, symmetry failure, or a nonpositive pivot returns `-1` and no output. This benchmark maps the source's assertion and `ValueError` failures to that sentinel.
- Output is the full `n*n` lower-triangular matrix as little-endian binary64 values. The function returns its byte length (`8*n*n`); insufficient capacity or a null output pointer returns `-2` without writing.

## Workload and oracle

[`workload.json`](workload.json) covers the pinned example, irrational pivots, accepted/rejected symmetry differences, positive semidefinite and indefinite matrices, maximum dimension/output, and capacity boundaries. The independent oracle is [`cholesky_decomposition_oracle.py`](../../cholesky_decomposition_oracle.py). Output comparison uses absolute and relative tolerances of `1e-9`.

Pinned source: [TheAlgorithms/Python `cholesky_decomposition.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/cholesky_decomposition.py).

## Running and verifying

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm cholesky_decomposition --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm cholesky_decomposition
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm cholesky_decomposition --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/cholesky_decomposition.c`](../../../c/c/cholesky_decomposition.c) |
| C3 | [`c3/c/cholesky_decomposition.c3`](../../../c3/c/cholesky_decomposition.c3) |
| C++ | [`cpp/c/cholesky_decomposition.cpp`](../../../cpp/c/cholesky_decomposition.cpp) |
| Elisa | [`elisa/c/cholesky_decomposition.elisa`](../../../elisa/c/cholesky_decomposition.elisa) |
| Nim | [`nim/c/cholesky_decomposition.nim`](../../../nim/c/cholesky_decomposition.nim) |
| Odin | [`odin/c/cholesky_decomposition.odin`](../../../odin/c/cholesky_decomposition.odin) |
| Rust | [`rust/c/cholesky_decomposition.rs`](../../../rust/c/cholesky_decomposition.rs) |
| V | [`v/c/cholesky_decomposition.v`](../../../v/c/cholesky_decomposition.v) |
| Zig | [`zig/c/cholesky_decomposition.zig`](../../../zig/c/cholesky_decomposition.zig) |
