# Gaussian-Legendre Quadrature

This benchmark follows the pinned Fortran module's Gauss-Legendre quadrature tables for orders 1 through 5. It integrates a cubic polynomial over a finite interval using the module's decimal node and weight constants and its interval transform. The separate [`gauss_legendre`](../gauss_legendre/README.md) benchmark is the Java arithmetic-geometric iteration for approximating π.

## Contract

Input is `[order, a_milli, b_milli, c0_milli, c1_milli, c2_milli, c3_milli]`. The integral is for `f(x) = c0 + c1*x + c2*x² + c3*x³`; interval endpoints and coefficients are divided by 1000. Order is 1–5, endpoints are in `[-5,5]`, and coefficients are in `[-10,10]`. Invalid input returns `-1e300`.

The output is one binary64 integral estimate, compared with relative and absolute tolerance `1e-9`. The benchmark preserves the source's rounded 10-decimal node and weight tables and interval transformation. The callable-function interface is fixed to a cubic polynomial for a common cross-language ABI. The source's unimplemented orders above five and printing behavior are outside the contract.

## Pinned source

[TheAlgorithms/Fortran `gaussian_legendre.f90`](https://github.com/TheAlgorithms/Fortran/blob/c91199703b78bd2181051b01bd5269740e41e121/modules/maths/numerical_integration/gaussian_legendre.f90)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/gaussian_legendre.c`](../../../c/g/gaussian_legendre.c) |
| C3 | [`c3/g/gaussian_legendre.c3`](../../../c3/g/gaussian_legendre.c3) |
| C++ | [`cpp/g/gaussian_legendre.cpp`](../../../cpp/g/gaussian_legendre.cpp) |
| Elisa | [`elisa/g/gaussian_legendre.elisa`](../../../elisa/g/gaussian_legendre.elisa) |
| Nim | [`nim/g/gaussian_legendre.nim`](../../../nim/g/gaussian_legendre.nim) |
| Odin | [`odin/g/gaussian_legendre.odin`](../../../odin/g/gaussian_legendre.odin) |
| Rust | [`rust/g/gaussian_legendre.rs`](../../../rust/g/gaussian_legendre.rs) |
| V | [`v/g/gaussian_legendre.v`](../../../v/g/gaussian_legendre.v) |
| Zig | [`zig/g/gaussian_legendre.zig`](../../../zig/g/gaussian_legendre.zig) |
