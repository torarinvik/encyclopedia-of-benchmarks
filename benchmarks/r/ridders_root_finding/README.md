# Ridders root finding

This package benchmarks Ridders' bracket-preserving root iteration. It is distinct from local bisection (midpoint-only reduction), false position (the endpoint chord intercept), secant (an unbracketed two-point update), Newton (a derivative-based update), and Brent's method (safeguarded secant and inverse-quadratic interpolation). Ridders instead evaluates the midpoint, applies a closed-form exponential interpolation correction using all three function values, and updates one side of the sign-changing bracket.

## Contract

The `float64_slice_io` input contains five finite, integer-valued binary64 values:

```text
[function_id, left_milli, right_milli, tolerance_micro, max_iterations]
```

The callbacks are `0: x²−2`, `1: x³−2`, `2: x³+x−1`, and `3: x`. Endpoints are divided by 1,000 and lie in `[-3,3]`; they must be ordered `left<right` and bracket a root by an exact endpoint zero or opposite endpoint signs. These four polynomials have at most one root in an accepted bracket. The requested width is `tolerance_micro/1,000,000`, for `1<=tolerance_micro<=1000`; the iteration cap is 24 through 32.

An exact endpoint root is returned before iteration. Otherwise each update evaluates the midpoint and returns it if it is an exact root. It then computes `D=sqrt(f(m)²−f(a)f(b))` and `z=m+(m−a)*sign(f(a)−f(b))*f(m)/D`. A nonpositive or nonfinite radicand, a zero or nonfinite denominator, or a candidate outside the open bracket returns -3 without writing output. The endpoint with the same sign as `f(z)` is replaced. The midpoint of the updated bracket is returned when its width is at most the requested tolerance; reaching the cap first returns -3. Malformed or unbracketed input returns -1 before output validation. A valid input with a null output or capacity below one returns -2. All error statuses leave output untouched.

The primary oracle follows the binary64 Ridders update. The independent verifier uses 80-digit Decimal bisection on the fixed polynomials, without following Ridders' iteration path. The workload uses one float64 output with absolute tolerance `1.1e-3` and relative tolerance `1e-12`. See [`workload.json`](workload.json), [`ridders_root_finding_oracle.py`](../../ridders_root_finding_oracle.py), and [`ridders_root_finding_verifier_oracle.py`](../../ridders_root_finding_verifier_oracle.py).

## Provenance and rights

The implementation is a clean-room translation of the mathematical algorithm description in SciPy's [`ridder` reference](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.ridder.html), which cites C. F. J. Ridders, “A New Algorithm for Computing a Single Root of a Real Continuous Function,” *IEEE Transactions on Circuits and Systems* 26 (1979), 979–980. No SciPy or Numerical Recipes implementation code or prose was copied. The fixed functions, bounded ABI, workload, and ports are original benchmark choices. See [`RIGHTS.md`](RIGHTS.md) for the source record.

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/ridders_root_finding.c`](../../../c/r/ridders_root_finding.c) |
| C3 | [`c3/r/ridders_root_finding.c3`](../../../c3/r/ridders_root_finding.c3) |
| C++ | [`cpp/r/ridders_root_finding.cpp`](../../../cpp/r/ridders_root_finding.cpp) |
| Elisa | [`elisa/r/ridders_root_finding.elisa`](../../../elisa/r/ridders_root_finding.elisa) |
| Mojo | [`mojo/r/ridders_root_finding.mojo`](../../../mojo/r/ridders_root_finding.mojo) |
| Nim | [`nim/r/ridders_root_finding.nim`](../../../nim/r/ridders_root_finding.nim) |
| Odin | [`odin/r/ridders_root_finding.odin`](../../../odin/r/ridders_root_finding.odin) |
| Rust | [`rust/r/ridders_root_finding.rs`](../../../rust/r/ridders_root_finding.rs) |
| V | [`v/r/ridders_root_finding.v`](../../../v/r/ridders_root_finding.v) |
| Zig | [`zig/r/ridders_root_finding.zig`](../../../zig/r/ridders_root_finding.zig) |

The source inventory is checked by [`check_ridders_root_finding_package.py`](../../check_ridders_root_finding_package.py).
