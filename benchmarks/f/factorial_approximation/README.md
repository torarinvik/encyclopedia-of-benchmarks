# Factorial approximation

Evaluates Ramanujan's floating-point approximation for the factorial function.

## Contract

- Uses the unary binary64 ABI: `double factorial_approximation(double x)`.
- Finite inputs in `[0, 170]` are accepted. Other inputs return `-1.0`.
- The result is `sqrt(pi) * pow(x / e, x) * pow(8 * pow(x, 3) + 4 * pow(x, 2) + x + 1 / 30, 1 / 6)`, evaluated in that operation order.
- This is an approximation to `x!` (equivalently `Gamma(x+1)` for nonnegative x), not an exact factorial. In particular, the pinned formula returns about `1.0055138583158989` at `x = 0`, rather than exact `0! = 1`.
- The workload compares binary64 results with relative tolerance `1e-12` and absolute tolerance `1e-12` to allow for platform `pow` and `sqrt` rounding.

## Source semantics

The benchmark follows the pinned [TheAlgorithms Dart `factorial_approximation.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/factorial_approximation.dart). Its `factorial(double x)` directly evaluates Ramanujan's approximation using `sqrt(pi)`, `pow(x/e, x)`, and the sixth root of the polynomial correction. The source does not validate its input; this benchmark defines a finite range `[0, 170]`, which keeps the approximation finite in binary64. Negative, non-finite, and larger inputs map to `-1.0`.

## Workload and build

[`workload.json`](workload.json) covers zero, fractional inputs, integer inputs, a large finite result, and invalid bounds. Build and record with the float64 unary ABI:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm factorial_approximation --language c
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/f/factorial_approximation/c/build.json
```

The nine implementations are in `c/f/factorial_approximation.c`, `c3/f/factorial_approximation.c3`, `cpp/f/factorial_approximation.cpp`, `elisa/f/factorial_approximation.elisa`, `nim/f/factorial_approximation.nim`, `odin/f/factorial_approximation.odin`, `rust/f/factorial_approximation.rs`, `v/f/factorial_approximation.v`, and `zig/f/factorial_approximation.zig`.
