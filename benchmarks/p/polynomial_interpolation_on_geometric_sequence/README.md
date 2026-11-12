# Polynomial interpolation on a geometric sequence

This package implements Library Checker `polynomial_interpolation_on_geometric_sequence`.
Given `y_i` at points `x_i=a*r^i` over `F_998244353`, it returns the
coefficients of the unique polynomial of degree less than `N` passing through
those pairs.

## Bounded contract

The exported C ABI is
`int64_t polynomial_interpolation_on_geometric_sequence(const int64_t *input, size_t length, uint8_t *output, size_t capacity)`.
It accepts `[N,a,r,y_0,...,y_(N-1)]`, with `0<=N<=8` and `a`, `r`, and each
`y_i` in `0..998244352`. The official task guarantees that all `a*r^i` nodes
are pairwise distinct; these ports check that promise defensively. `N=0` is
valid and returns zero bytes when given a nonnull output pointer. The local
maximum input is 11 words and the maximum output is 64 bytes.

Success returns `8*N` and writes exactly `N` little-endian signed 64-bit
coefficients, including trailing zeros. Malformed input or repeated nodes
returns `-1`. Valid input with a null output pointer or capacity below `8*N`
returns `-2` without writes. Thus an empty result still requires a nonnull
output pointer, while zero capacity is sufficient for `N=0`.

The primary method uses q-Newton divided differences. With the in-place
table entry at endpoint `i` and order `k`, the denominator is
`x_i-x_(i-k)=a*r^(i-k)*(r^k-1)`. The diagonal differences become coefficients
in the Newton basis, which is expanded into monomial coefficients. The
bounded implementation uses `O(N^2 log MOD)` field operations because it
computes each modular inverse by exponentiation, and `O(N)` auxiliary storage.
The independent oracle solves a Vandermonde system by modular Gauss-Jordan
elimination in `O(N^3)` field operations and `O(N^2)` storage.

## Source and rights

Official statement: [Library Checker — Polynomial Interpolation (Geometric Sequence)](https://github.com/yosupo06/library-checker-problems/blob/master/polynomial/polynomial_interpolation_on_geometric_sequence/task.md).
Official limits: [info.toml](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/polynomial/polynomial_interpolation_on_geometric_sequence/info.toml).
The official constraints allow `N<=524288`; this package intentionally uses
`N<=8` to keep the scalar q-Newton method and all ten ports bounded. The task
repository is Apache-2.0; see [RIGHTS.md](RIGHTS.md). The local profile,
implementations, workload, oracles, and prose are clean-room.

Workload and package checker: [workload.json](workload.json) and
[verify_workload.py](verify_workload.py). The workload is intended for the
shared byte-output runner and verifier, and this package is registered in both.

| Language | Source |
|---|---|
| C | [c/p/polynomial_interpolation_on_geometric_sequence.c](../../../c/p/polynomial_interpolation_on_geometric_sequence.c) |
| C3 | [c3/p/polynomial_interpolation_on_geometric_sequence.c3](../../../c3/p/polynomial_interpolation_on_geometric_sequence.c3) |
| C++ | [cpp/p/polynomial_interpolation_on_geometric_sequence.cpp](../../../cpp/p/polynomial_interpolation_on_geometric_sequence.cpp) |
| Elisa | [elisa/p/polynomial_interpolation_on_geometric_sequence.elisa](../../../elisa/p/polynomial_interpolation_on_geometric_sequence.elisa) |
| Mojo | [mojo/p/polynomial_interpolation_on_geometric_sequence.mojo](../../../mojo/p/polynomial_interpolation_on_geometric_sequence.mojo) |
| Nim | [nim/p/polynomial_interpolation_on_geometric_sequence.nim](../../../nim/p/polynomial_interpolation_on_geometric_sequence.nim) |
| Odin | [odin/p/polynomial_interpolation_on_geometric_sequence.odin](../../../odin/p/polynomial_interpolation_on_geometric_sequence.odin) |
| Rust | [rust/p/polynomial_interpolation_on_geometric_sequence.rs](../../../rust/p/polynomial_interpolation_on_geometric_sequence.rs) |
| V | [v/p/polynomial_interpolation_on_geometric_sequence.v](../../../v/p/polynomial_interpolation_on_geometric_sequence.v) |
| Zig | [zig/p/polynomial_interpolation_on_geometric_sequence.zig](../../../zig/p/polynomial_interpolation_on_geometric_sequence.zig) |
