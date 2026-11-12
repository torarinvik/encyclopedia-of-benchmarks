# Modular adjugate matrix

Compute the full adjugate of a square matrix over the prime field
`F_998244353`. The result is the transpose of the signed cofactor matrix. Each
entry is computed from its own minor, so the operation is defined when the
input is singular as well as when it is invertible.

## Contract

Input is `[N, row-major matrix entries...]`, with `1 <= N <= 6`, exactly
`1 + N*N` signed 64-bit values, and each entry in `[0, 998244352]`.

Output is `N*N` signed 64-bit little-endian values containing the row-major
adjugate, with every residue represented in `[0, 998244352]`. The call returns
the number of bytes written (`8*N*N`). Malformed input returns `-1`; a null or
short output buffer returns `-2` without writing. The maximum input is 37
values and the maximum output is 288 bytes.

The ports build every signed minor and compute each minor determinant with a
subset dynamic program over permutations. For a minor of dimension `k`, the
determinant step takes `O(k^2*2^k)` time and `O(2^k)` temporary storage; the
complete adjugate takes `O(N^4*2^N)` time and `O(N^2 + 2^N)` auxiliary space.
This is a deliberately small deterministic profile rather than a large-matrix
implementation.

This benchmark is distinct from scalar determinant and ordinary inverse
benchmarks: it returns all `N*N` cofactors in transposed order, including for
singular matrices. The independent oracle uses exact recursive integer
cofactor expansion, then reduces modulo the field prime. Its API is
`expected_output(values, capacity=None, output_is_null=False,
input_is_null=False, input_length=None) -> (status, bytes)`;
`expected_adjugate(values)` returns the flattened matrix, and
`certificate_holds(values, candidate)` checks every output cell against its
signed-minor certificate.

## Provenance

Problem shape and field: [Library Checker — Adjugate Matrix](https://judge.yosupo.jp/problem/adjugate_matrix), with task data maintained in the
[Library Checker problems repository](https://github.com/yosupo06/library-checker-problems).
The implementations here are clean-room bounded ports of the mathematical
adjugate definition; no reference implementation or test data was copied.

[`workload.json`](workload.json) covers one-by-one, nonsymmetric invertible,
singular rank-one, all-zero, diagonal, malformed-input, and output-buffer
cases.

## Implementations

| Language | Source |
|---|---|
| C | [`c/a/adjugate_matrix.c`](../../../c/a/adjugate_matrix.c) |
| C3 | [`c3/a/adjugate_matrix.c3`](../../../c3/a/adjugate_matrix.c3) |
| C++ | [`cpp/a/adjugate_matrix.cpp`](../../../cpp/a/adjugate_matrix.cpp) |
| Elisa | [`elisa/a/adjugate_matrix.elisa`](../../../elisa/a/adjugate_matrix.elisa) |
| Mojo | [`mojo/a/adjugate_matrix.mojo`](../../../mojo/a/adjugate_matrix.mojo) |
| Nim | [`nim/a/adjugate_matrix.nim`](../../../nim/a/adjugate_matrix.nim) |
| Odin | [`odin/a/adjugate_matrix.odin`](../../../odin/a/adjugate_matrix.odin) |
| Rust | [`rust/a/adjugate_matrix.rs`](../../../rust/a/adjugate_matrix.rs) |
| V | [`v/a/adjugate_matrix.v`](../../../v/a/adjugate_matrix.v) |
| Zig | [`zig/a/adjugate_matrix.zig`](../../../zig/a/adjugate_matrix.zig) |
