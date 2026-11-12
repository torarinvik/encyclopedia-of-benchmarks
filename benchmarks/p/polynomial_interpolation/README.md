# Polynomial interpolation

This package implements Library Checker `polynomial_interpolation`. Given
distinct points `x_i` and values `y_i` in `F_998244353`, it returns the
coefficients `c_0,...,c_(N-1)` of the unique polynomial of degree less than
`N` that interpolates the pairs.

## Bounded contract

The exported C ABI is
`int64_t polynomial_interpolation(const int64_t *input, size_t length, uint8_t *output, size_t capacity)`.
It accepts
`[N,x_0,...,x_(N-1),y_0,...,y_(N-1)]`, with `1<=N<=12`, all field values in
`0..998244352`, and pairwise-distinct points. Success writes exactly `N`
little-endian signed 64-bit coefficients and returns `8*N` bytes, retaining
trailing zero coefficients. Malformed input returns `-1`; valid input with a
null output or capacity below `8*N` returns `-2` without writes. The maximum
input is 25 words and the maximum output is 96 bytes. The ports use
`O(N^3)` field operations and `O(N)` auxiliary storage. The independent
Vandermonde oracle also takes `O(N^3)` field operations and uses `O(N^2)` matrix
storage.

The primary method constructs each Lagrange basis polynomial
`L_i(X)=product_(j!=i)(X-x_j)`, divides by its nonzero value at `x_i`, scales
by `y_i`, and accumulates its coefficients. The independent oracle builds the
Vandermonde linear system and solves it with modular Gauss-Jordan elimination.

## Source and rights

Official statement: [Library Checker — Polynomial Interpolation](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/polynomial_interpolation/task.md).
Official limits: [info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/polynomial_interpolation/info.toml).
The official constraints allow `N<=131072`; this package intentionally uses
the bounded `N<=12` profile so direct cubic algorithms remain suitable for
cross-language benchmarks. The task repository is Apache-2.0; see
[RIGHTS.md](RIGHTS.md). The local profile, implementations, workload, oracles,
and prose are clean-room.

Workload and package checker: [workload.json](workload.json) and
[verify_workload.py](verify_workload.py). The workload is intended for the
shared byte-output runner and verifier.

| Language | Source |
|---|---|
| C | [c/p/polynomial_interpolation.c](../../../c/p/polynomial_interpolation.c) |
| C3 | [c3/p/polynomial_interpolation.c3](../../../c3/p/polynomial_interpolation.c3) |
| C++ | [cpp/p/polynomial_interpolation.cpp](../../../cpp/p/polynomial_interpolation.cpp) |
| Elisa | [elisa/p/polynomial_interpolation.elisa](../../../elisa/p/polynomial_interpolation.elisa) |
| Mojo | [mojo/p/polynomial_interpolation.mojo](../../../mojo/p/polynomial_interpolation.mojo) |
| Nim | [nim/p/polynomial_interpolation.nim](../../../nim/p/polynomial_interpolation.nim) |
| Odin | [odin/p/polynomial_interpolation.odin](../../../odin/p/polynomial_interpolation.odin) |
| Rust | [rust/p/polynomial_interpolation.rs](../../../rust/p/polynomial_interpolation.rs) |
| V | [v/p/polynomial_interpolation.v](../../../v/polynomial_interpolation.v) |
| Zig | [zig/p/polynomial_interpolation.zig](../../../zig/p/polynomial_interpolation.zig) |
