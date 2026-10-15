# `bisection_method`

This benchmark compares interval bisection for two fixed continuous functions:

- Equation 0: `f(x) = x^3 + 2x - 10`, used by the pinned C and R examples.
- Equation 1: `f(x) = x^3 - 4x - 9`, used by the pinned additional C++ example.

The pinned JavaScript implementation accepts an arbitrary callback and a fixed
iteration count. The C++ example in the primary C++ repository also uses a
fixed function and includes its own bracket search. Those interfaces cannot be
represented directly by one portable benchmark call, so this contract supplies
the equation and bracket explicitly and applies the same bisection procedure
to either equation. It measures bisection itself; it does not include automatic
bracket discovery or arbitrary callback dispatch.

## Input and result

The packed `i64` input is exactly
`[equation_id, left_milli, right_milli, tolerance_micro]`.

- `equation_id` is `0` or `1`, as listed above.
- Endpoints are signed thousandths in `[-100000, 100000]`; the left endpoint
  must be less than the right endpoint.
- `tolerance_micro` is in `[1, 1000000]`, representing an interval-width
  tolerance from `1e-6` through `1.0`.
- The endpoint function values must bracket a root. An endpoint that is
  exactly a root is returned directly.
- The function returns the midpoint of the final interval rounded to the
  nearest micro-unit. At most 64 bisections are performed.
- Malformed or out-of-range input returns `-1`. A non-bracketing interval or
  an interval that does not reach the requested width within 64 iterations
  returns `-2`.

The workload contains tight and coarse tolerances, narrow and wide brackets,
non-bracketing intervals, and malformed inputs. The root approximation uses
binary64 arithmetic in every port.

## Source references

- [TheAlgorithms/C `bisection_method.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/numerical_methods/bisection_method.c)
- [TheAlgorithms/C-Plus-Plus `bisection_method.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/bisection_method.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `bisection_method.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/numerical_methods/bisection_method.cpp)
- [TheAlgorithms/JavaScript `BisectionMethod.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/BisectionMethod.js)
- [TheAlgorithms/R `bisection_method.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/bisection_method.r)
