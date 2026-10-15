# Gaussian elimination

This package solves a bounded system of linear equations `A x = b` with Gaussian forward elimination and back substitution. Its input is packed as signed 64-bit slots `[n, A row-major n*n cells, b n cells]`; the result is an IEEE-754 binary64 solution vector written as little-endian bytes.

## Shared domain

- `n` is 2 through 8 and the input length is exactly `1+n*n+n`.
- `A` is symmetric tridiagonal, every diagonal entry is 32, and every adjacent off-diagonal entry is either 0 or -1.
- Every right-hand-side entry is an integer from -100 through 100.

These constraints make `A` strictly diagonally dominant with a positive diagonal, so it is nonsingular. Because elimination preserves the tridiagonal shape and every diagonal pivot stays above 31 while the only possible lower pivot-column entry has magnitude 1, the R and TypeScript partial-pivot variants do not swap rows. This matches the no-pivot C++, Python, and Rust variants. The narrow coefficient bounds also keep the Rust source's `f32` result close to the binary64 ports; workload tolerances are `1e-5` relative and `1e-4` absolute.

The C++ source is a console `main` program rather than a reusable function. Its port preserves its forward-elimination and back-substitution arithmetic in the benchmark ABI adapter, with console prompts omitted. The Python source provides separate forward-elimination and retroactive-resolution functions. Rust accepts an augmented matrix and uses its own `f32` elimination order; its port preserves that order and precision.

Malformed or out-of-domain inputs return `-1` with no output. A null or undersized output buffer returns `-2`. Success returns the number of output bytes, `8*n`.

## Pinned source implementations

- C++ [`numerical_methods/gaussian_elimination.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/gaussian_elimination.cpp) at `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`
- Python [`linear_algebra/gaussian_elimination.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/linear_algebra/gaussian_elimination.py) at `e1a2a8b016001309a73d5fec4818c35cca139795`
- R [`mathematics/gaussian_elimination.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/gaussian_elimination.r) at `f65344fabeea0ae33c1ca321af709447c1a8a4c2`
- Rust [`src/math/gaussian_elimination.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/gaussian_elimination.rs) at `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`
- TypeScript [`maths/gaussian_elimination.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/gaussian_elimination.ts) at `19b4ced86c99815f142d4a46a028f55487b8038a`

## Workload

[`workload.json`](workload.json) contains source-backed systems with known solution vectors and invalid/capacity cases.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/g/gaussian_elimination.c`](../../../c/g/gaussian_elimination.c) |
| C3 | [`c3/g/gaussian_elimination.c3`](../../../c3/g/gaussian_elimination.c3) |
| C++ | [`cpp/g/gaussian_elimination.cpp`](../../../cpp/g/gaussian_elimination.cpp) |
| Elisa | [`elisa/g/gaussian_elimination.elisa`](../../../elisa/g/gaussian_elimination.elisa) |
| Nim | [`nim/g/gaussian_elimination.nim`](../../../nim/g/gaussian_elimination.nim) |
| Odin | [`odin/g/gaussian_elimination.odin`](../../../odin/g/gaussian_elimination.odin) |
| Rust | [`rust/g/gaussian_elimination.rs`](../../../rust/g/gaussian_elimination.rs) |
| V | [`v/g/gaussian_elimination.v`](../../../v/g/gaussian_elimination.v) |
| Zig | [`zig/g/gaussian_elimination.zig`](../../../zig/g/gaussian_elimination.zig) |
