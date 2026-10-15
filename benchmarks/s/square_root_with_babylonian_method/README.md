# Babylonian square root

Approximates the square root with the source's two-value Babylonian iteration.

## Contract

- Uses the unary binary64 ABI. Inputs in `[1, 1,000,000]` are rounded to binary32 before the source algorithm runs; the binary32 result is widened back to binary64.
- Inputs outside that range return `-1.0`. The lower bound excludes the source routine's premature return for values below one.
- Starts with `a = num`, `b = 1`, and `epsilon = 0.000001`. While the binary32 subtraction `a - b`, widened for comparison to epsilon, is greater than epsilon, update `a = (a + b) / 2` and then `b = num / a`, all in binary32.
- Results are compared with absolute and relative tolerances of `2e-6`, allowing for the source's binary32 output and stopping threshold.

## Source semantics

This follows pinned [TheAlgorithms Java `SquareRootWithBabylonianMethod.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/SquareRootWithBabylonianMethod.java). Its method accepts and returns `float`. It initializes `a` to the input and `b` to 1, tests `a - b > 1e-6` (not an absolute difference), updates `a` before `b`, and returns `a`. Consequently inputs below one return unchanged; the benchmark excludes them and also bounds large inputs to keep iteration cost and float arithmetic controlled. The ABI result is the source float widened to binary64.

## Workload and build

[`workload.json`](workload.json) covers one, non-square values, perfect squares, and both contract boundaries, along with invalid values.

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm square_root_with_babylonian_method --language rust
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/s/square_root_with_babylonian_method/rust/build.json
```

The implementations are in `c/s/square_root_with_babylonian_method.c`, `c3/s/square_root_with_babylonian_method.c3`, `cpp/s/square_root_with_babylonian_method.cpp`, `elisa/s/square_root_with_babylonian_method.elisa`, `nim/s/square_root_with_babylonian_method.nim`, `odin/s/square_root_with_babylonian_method.odin`, `rust/s/square_root_with_babylonian_method.rs`, `v/s/square_root_with_babylonian_method.v`, and `zig/s/square_root_with_babylonian_method.zig`.
