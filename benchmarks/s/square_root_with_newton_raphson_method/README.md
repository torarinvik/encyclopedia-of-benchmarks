# Square root with Newton–Raphson

This benchmark follows the pinned Java `squareRoot(int n)` routine. It starts with the input itself as the initial guess and applies Newton's update until two consecutive guesses differ by at most `1e-7`.

## Contract

- The binary64 input must represent an integer from 1 through 2,147,483,647, matching the source's positive signed 32-bit argument domain.
- The result is the final Newton iterate using `root = 0.5 * (guess + n / guess)` and the source stopping rule `abs(root - guess) <= 1e-7`.
- Nonintegral, nonfinite, zero, negative, and out-of-range inputs return `-1e300` as the benchmark's invalid-input sentinel.
- The method takes O(log n) iterations from its initial guess and uses O(1) auxiliary space.

This is distinct from [`babylonian_sqrt`](../../b/babylonian_sqrt/README.md), which starts from half the input and stops based on squared residual against a different tolerance. The workload compares outputs with `1e-6` absolute tolerance to accommodate the source's approximate stopping rule.

## Workload and implementations

[`workload.json`](workload.json) uses the `float64_unary` ABI and covers small roots, non-square inputs, the upper signed 32-bit endpoint, and invalid inputs.

| Language | Source |
| --- | --- |
| C | [`c/s/square_root_with_newton_raphson_method.c`](../../../c/s/square_root_with_newton_raphson_method.c) |
| C3 | [`c3/s/square_root_with_newton_raphson_method.c3`](../../../c3/s/square_root_with_newton_raphson_method.c3) |
| C++ | [`cpp/s/square_root_with_newton_raphson_method.cpp`](../../../cpp/s/square_root_with_newton_raphson_method.cpp) |
| Elisa | [`elisa/s/square_root_with_newton_raphson_method.elisa`](../../../elisa/s/square_root_with_newton_raphson_method.elisa) |
| Nim | [`nim/s/square_root_with_newton_raphson_method.nim`](../../../nim/s/square_root_with_newton_raphson_method.nim) |
| Odin | [`odin/s/square_root_with_newton_raphson_method.odin`](../../../odin/s/square_root_with_newton_raphson_method.odin) |
| Rust | [`rust/s/square_root_with_newton_raphson_method.rs`](../../../rust/s/square_root_with_newton_raphson_method.rs) |
| V | [`v/s/square_root_with_newton_raphson_method.v`](../../../v/s/square_root_with_newton_raphson_method.v) |
| Zig | [`zig/s/square_root_with_newton_raphson_method.zig`](../../../zig/s/square_root_with_newton_raphson_method.zig) |

Pinned Java source: [`SquareRootWithNewtonRaphsonMethod.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SquareRootWithNewtonRaphsonMethod.java).
