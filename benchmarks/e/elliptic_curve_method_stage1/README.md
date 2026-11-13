# Elliptic-Curve Method Stage 1

This package benchmarks the deterministic stage-1 factor-detection core of
Lenstra's elliptic-curve method (ECM). It is a bounded subroutine profile, not
a complete integer factorizer: it does not generate random curves, run stage 2,
or attempt the Library Checker proposal's large `N <= 10^38` range.

The current Library Checker repository has an in-progress “Factorize (Large)”
proposal (#1395) for prime-factorizing values up to `10^38`. Its proposal notes
that the intended family includes elliptic-curve factorization and contrasts
it with Pollard rho on large semiprimes. Local `pollard_rho_*` packages use
polynomial cycle walks, and `pollard_p_minus_one_factorization` raises a scalar
modular state to smooth exponents in the multiplicative group. This package
uses smooth scalar multiplication in an elliptic-curve group. It therefore
measures ECM's distinct factor-discovery step.

## Contract

The exported symbol is `elliptic_curve_method_stage1` with the
`i64_array_scalar` ABI. Input is exactly `[N,A,X,Y,B1]`, where `(X,Y)` lies on
the Montgomery-form curve `y^2 = x^3 + A*x^2 + x (mod N)`.

- `N` is an odd square-free integer in `3..=10_000`.
- `A`, `X`, and `Y` are in `0..N-1`; `gcd(A^2-4,N)=1` ensures the curve is
  nonsingular modulo each prime factor.
- `2 <= B1 <= 32` is the stage-1 smoothness bound.
- The point equation must hold modulo `N`.
- Return `1` if any stage checkpoint has `1 < gcd(Z,N) < N`. If a checkpoint
  has `gcd(Z,N)=N`, the point is infinity modulo every prime factor, so the
  curve terminates with result `0`; otherwise the bounded schedule ends with
  `0` when it exposes no proper factor. Malformed input returns `-1`.
- The maximum valid and parseable input lengths are 5 and 6 signed 64-bit
  words. Fixed workspace is 1024 bytes.

For each prime `q <= B1`, the primary multiplies the current point by the
largest `q^e <= B1`, then checks the projective denominator's gcd with `N`.
Montgomery X:Z differential addition and a binary ladder avoid modular
inversion in the curve arithmetic. The independent oracle trial-factors the
small square-free modulus and uses affine two-coordinate group operations
separately in every prime field; it compares whether the same checkpoint
separates the prime factors.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/e/elliptic_curve_method_stage1.c`](../../../c/e/elliptic_curve_method_stage1.c) |
| C3 | [`c3/e/elliptic_curve_method_stage1.c3`](../../../c3/e/elliptic_curve_method_stage1.c3) |
| C++ | [`cpp/e/elliptic_curve_method_stage1.cpp`](../../../cpp/e/elliptic_curve_method_stage1.cpp) |
| Elisa | [`elisa/e/elliptic_curve_method_stage1.elisa`](../../../elisa/e/elliptic_curve_method_stage1.elisa) |
| Mojo | [`mojo/e/elliptic_curve_method_stage1.mojo`](../../../mojo/e/elliptic_curve_method_stage1.mojo) |
| Nim | [`nim/e/elliptic_curve_method_stage1.nim`](../../../nim/e/elliptic_curve_method_stage1.nim) |
| Odin | [`odin/e/elliptic_curve_method_stage1.odin`](../../../odin/e/elliptic_curve_method_stage1.odin) |
| Rust | [`rust/e/elliptic_curve_method_stage1.rs`](../../../rust/e/elliptic_curve_method_stage1.rs) |
| V | [`v/e/elliptic_curve_method_stage1.v`](../../../v/e/elliptic_curve_method_stage1.v) |
| Zig | [`zig/e/elliptic_curve_method_stage1.zig`](../../../zig/e/elliptic_curve_method_stage1.zig) |

## Provenance

The motivating task is the in-progress [Library Checker “Factorize (Large)”
proposal #1395](https://github.com/yosupo06/library-checker-problems/issues/1395).
The mathematical algorithm is described by [Lenstra's original ECM
paper](https://annals.math.princeton.edu/1987/126-3/p09); Montgomery's x-only
ladder is based on [Montgomery's factorization paper](https://doi.org/10.1090/S0025-5718-1987-0866113-7).
Only algorithm descriptions and task metadata were consulted. See
[`RIGHTS.md`](RIGHTS.md) for licensing and implementation notes.
