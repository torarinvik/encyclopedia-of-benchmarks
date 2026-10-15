# Fibonacci number check

Checks whether a signed integer belongs to the Fibonacci sequence using the identity that `n` is Fibonacci exactly when one of `5n² + 4` and `5n² - 4` is a perfect square.

## Contract

- Uses the signed 64-bit scalar ABI: `int64_t fibonacci_number_check(int64_t input)`.
- Valid input range is `[-1,300,000,000, 1,300,000,000]`. This keeps `5 * input * input ± 4` inside signed 64-bit range.
- Return `1` for Fibonacci values, including negative Fibonacci values and zero; return `0` otherwise.
- Values outside the valid range return `-1`.

## Source semantics

The benchmark follows the pinned [TheAlgorithms Java `FibonacciNumberCheck`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/FibonacciNumberCheck.java). Its predicate checks whether either `5 * n * n + 4` or `5 * n * n - 4` is a perfect square. The source does not reject negative inputs, and its square identity is symmetric, so negative Fibonacci values are accepted as well. The source computes a square root with `Math.sqrt`, casts it to `long`, and checks the square exactly. The ports use integer binary search for exact squares, preserving that mathematical predicate without floating-point square-root rounding. The shared ±1.3e9 range prevents overflow in the source's signed `long` intermediates.

## Workload and build

[`workload.json`](workload.json) includes zero, positive and negative Fibonacci values, nearby nonmembers, the range boundaries, and out-of-range inputs. Build and record with the scalar ABI:

```sh
python3 benchmarks/build_scalar.py --algorithm fibonacci_number_check --language c
python3 benchmarks/run_scalar.py --algorithm fibonacci_number_check
```

The nine implementations are in `c/f/fibonacci_number_check.c`, `c3/f/fibonacci_number_check.c3`, `cpp/f/fibonacci_number_check.cpp`, `elisa/f/fibonacci_number_check.elisa`, `nim/f/fibonacci_number_check.nim`, `odin/f/fibonacci_number_check.odin`, `rust/f/fibonacci_number_check.rs`, `v/f/fibonacci_number_check.v`, and `zig/f/fibonacci_number_check.zig`.
