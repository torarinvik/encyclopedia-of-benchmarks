# Dormand–Prince adaptive ODE solver

This package benchmarks the Dormand–Prince embedded fifth/fourth-order Runge–Kutta pair with adaptive step acceptance and rejection. It is distinct from local [`runge_kutta_fehlberg_45`](../../r/runge_kutta_fehlberg_45/README.md), which uses a different Fehlberg tableau and advances fixed caller-selected steps. The local [`runge_kutta`](../../r/runge_kutta/README.md) and [`runge_kutta_gills`](../../r/runge_kutta_gills/README.md) profiles are also fixed-step methods. This profile includes Dormand–Prince's local-error controller and reuse of the last stage as the next step's first derivative (FSAL).

## Contract

The `float64_slice_io` input is six finite exact integer-valued float64 fields:

```text
[function_id, y0_milli, x0_milli, x_end_milli, tolerance_exponent, max_attempts]
```

IDs 0 through 3 select `y'=y`, `y'=x+y`, `y'=sin(x)`, and `y'=1`. The initial state and both endpoints are divided by 1,000 and lie in `[-1,1]`; `x_end` must exceed `x0`. The internal absolute and relative tolerances are both `10^-tolerance_exponent`, with exponent 8 or 9. This lower bound keeps both requested tolerances below the suite's `2e-7` absolute and relative result comparison tolerance. The valid attempt budget is 64 through 128.

The initial step is `min((x_end-x0)/4, 0.25)` and no step exceeds 0.25. Each attempt computes the seven-stage Dormand–Prince 5(4) pair. The embedded error is scaled by `tol*(1+max(abs(y),abs(y5)))`; the fifth-order result is committed when the normalized error is at most one. Rejected steps preserve the current state and cached derivative. Accepted steps reuse the seventh stage through FSAL. The step-size multiplier is `0.9*error_norm^(-1/5)`, clamped to `[0.2,5]`; zero estimated error selects 5.

The successful output is one float64 value, the approximation to `y(x_end)`. Malformed input returns -1 before output validation. A null output or capacity below one returns -2. A nonfinite numerical state or exhausted attempt budget returns -3. Every error leaves output untouched. Maximum valid/parseable input lengths are 6/7 values; workspace declares one output float64 (8 bytes), with all integration state held in scalar locals.

The primary oracle follows the adaptive tableau. The independent oracle evaluates closed-form solutions for all four callbacks. See [`workload.json`](workload.json), [`primary_oracle.py`](primary_oracle.py), and [`independent_oracle.py`](independent_oracle.py).

## Provenance and rights

The implementation is a clean-room translation of the mathematical method described by SciPy's official [`integrate.RK45` reference](https://docs.scipy.org/doc/scipy/reference/generated/scipy.integrate.RK45.html), which identifies the Dormand–Prince 5(4) pair and cites J. R. Dormand and P. J. Prince, “A family of embedded Runge-Kutta formulae,” *Journal of Computational and Applied Mathematics* 6(1), 1980, DOI [10.1016/0771-050X(80)90013-3](https://doi.org/10.1016/0771-050X(80)90013-3). SciPy's documentation is distributed under its modified BSD license; no SciPy source code or prose was copied. Callback choices, input encoding, bounds, workload, and ports are original. See [`RIGHTS.md`](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/d/dormand_prince_54_adaptive_ode.c`](../../../c/d/dormand_prince_54_adaptive_ode.c) |
| C3 | [`c3/d/dormand_prince_54_adaptive_ode.c3`](../../../c3/d/dormand_prince_54_adaptive_ode.c3) |
| C++ | [`cpp/d/dormand_prince_54_adaptive_ode.cpp`](../../../cpp/d/dormand_prince_54_adaptive_ode.cpp) |
| Elisa | [`elisa/d/dormand_prince_54_adaptive_ode.elisa`](../../../elisa/d/dormand_prince_54_adaptive_ode.elisa) |
| Mojo | [`mojo/d/dormand_prince_54_adaptive_ode.mojo`](../../../mojo/d/dormand_prince_54_adaptive_ode.mojo) |
| Nim | [`nim/d/dormand_prince_54_adaptive_ode.nim`](../../../nim/d/dormand_prince_54_adaptive_ode.nim) |
| Odin | [`odin/d/dormand_prince_54_adaptive_ode.odin`](../../../odin/d/dormand_prince_54_adaptive_ode.odin) |
| Rust | [`rust/d/dormand_prince_54_adaptive_ode.rs`](../../../rust/d/dormand_prince_54_adaptive_ode.rs) |
| V | [`v/d/dormand_prince_54_adaptive_ode.v`](../../../v/d/dormand_prince_54_adaptive_ode.v) |
| Zig | [`zig/d/dormand_prince_54_adaptive_ode.zig`](../../../zig/d/dormand_prince_54_adaptive_ode.zig) |

The source inventory is checked by [`check_dormand_prince_54_adaptive_ode_package.py`](../../check_dormand_prince_54_adaptive_ode_package.py).
