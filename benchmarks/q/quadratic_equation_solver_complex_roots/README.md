# Quadratic equation complex roots

This benchmark ports `solveEquation(a, b, c)` from the pinned Java
[`QuadraticEquationSolver`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/QuadraticEquationSolver.java).
It preserves the source's plus-root-first ordering and its complex conjugate
branch. The pinned C++ `quadratic_equations_complex_numbers.cpp` computes the same real or complex root pair; its root order and imaginary-component representation are normalized to this contract.

## Contract

- Input uses the `i64_array_float64` ABI and is packed as
  `[a, b, c, component]`. Coefficients are integers in `[-1,000,000,
  1,000,000]`; `a` must be nonzero.
- Components `0` and `1` select the real parts of the first and second roots.
  Components `2` and `3` select their imaginary parts. Root 0 is the
  `(-b + sqrt(discriminant)) / (2a)` branch, and root 1 is the minus branch.
- A positive discriminant returns two real roots. Their imaginary fields are
  null in the Java source; selectors `2` and `3` return `-1e300` for those
  absent fields. A zero discriminant returns one real root; only selector `0`
  returns it. A negative discriminant returns two complex roots with the
  source's signed imaginary parts.
- A zero leading coefficient, invalid selector, out-of-range coefficient, or
  malformed packed input returns `-1e300`. The parser accepts up to five
  values to admit a one-extra-value malformed record.
- Coefficient bounds keep the integer discriminant exact in binary64 and the
  resulting root components finite. The direct quadratic formula and the
  source's root order are preserved.

The independent oracle computes the real and imaginary components directly
from the discriminant. The workload covers positive, zero, and negative discriminants,
negative leading coefficients, absent/null components, coefficient bounds,
and malformed input.

## Pinned source

The pinned C++ [`quadratic_equations_complex_numbers.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/quadratic_equations_complex_numbers.cpp) returns the same root pair but places the minus branch first and reports real-root imaginary parts as zero; the shared contract normalizes branch order and nullable-field behavior.


The Java source revision is
[`QuadraticEquationSolver.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/QuadraticEquationSolver.java)
at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/q/quadratic_equation_solver_complex_roots.c`](../../../c/q/quadratic_equation_solver_complex_roots.c) |
| C3 | [`c3/q/quadratic_equation_solver_complex_roots.c3`](../../../c3/q/quadratic_equation_solver_complex_roots.c3) |
| C++ | [`cpp/q/quadratic_equation_solver_complex_roots.cpp`](../../../cpp/q/quadratic_equation_solver_complex_roots.cpp) |
| Elisa | [`elisa/q/quadratic_equation_solver_complex_roots.elisa`](../../../elisa/q/quadratic_equation_solver_complex_roots.elisa) |
| Nim | [`nim/q/quadratic_equation_solver_complex_roots.nim`](../../../nim/q/quadratic_equation_solver_complex_roots.nim) |
| Odin | [`odin/q/quadratic_equation_solver_complex_roots.odin`](../../../odin/q/quadratic_equation_solver_complex_roots.odin) |
| Rust | [`rust/q/quadratic_equation_solver_complex_roots.rs`](../../../rust/q/quadratic_equation_solver_complex_roots.rs) |
| V | [`v/q/quadratic_equation_solver_complex_roots.v`](../../../v/q/quadratic_equation_solver_complex_roots.v) |
| Zig | [`zig/q/quadratic_equation_solver_complex_roots.zig`](../../../zig/q/quadratic_equation_solver_complex_roots.zig) |

The workload is [`workload.json`](workload.json), and the oracle is
[`quadratic_equation_solver_oracle.py`](../../quadratic_equation_solver_oracle.py).
