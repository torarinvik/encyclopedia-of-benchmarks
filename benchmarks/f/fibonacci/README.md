# Fibonacci

## Contract

Return the zero-indexed Fibonacci number defined by `F(0) = 0`, `F(1) = 1`, and `F(n) = F(n - 1) + F(n - 2)`. Inputs from `0` through `92` return the exact result as a signed 64-bit integer. Inputs outside that range return `-1`, since `F(93)` exceeds the signed 64-bit ABI range.

The exported C ABI entry point is:

```c
int64_t fibonacci(int64_t n);
```

The local implementations use the same iterative two-value recurrence. Upstream files differ in indexing and implementation: the C example uses a one-based argument and naive recursion, C++ uses zero-based naive recursion, and the Rust source includes several conventions and implementations. The local contract makes the zero-based sequence explicit and keeps the benchmark workload within the exact signed 64-bit range.

The former climbing-stairs benchmark used the same recurrence: for its valid
range `1 <= n <= 45`, the answer is `fibonacci(n+1)`. Its catalog entry
maps here with that explicit index shift. The Fibonacci function itself does
not enforce the former climbing-stairs input bounds; callers reproducing that
contract must check them separately. Source references: [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/ClimbingStairs.java),
[JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/ClimbingStairs.js),
[Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/climbing_stairs.py),
and [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/dynamic_programming/climbing_stairs.rb).

The MATLAB-Octave [shifted `fib` source](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/project-euler/Problem2/fib.m)
uses the same recurrence with `fib(n)=F(n+2)`. Its former bounded profile
maps to `fibonacci(n+2)` for `0 <= n <= 90`; the original input validation
must be applied separately. The former C draft also computed the next
unrepresentable Fibonacci value on its maximum input; the shared implementation
stops after the requested value.

## Workload and measurement

[`workload.json`](workload.json) covers boundary values, representative sequence positions, the maximum supported input, a negative input, and the first out-of-range value. The C11 scalar runner checks each expected result before timing, runs two warmup batches, then records seven samples of 10,000 calls each. Input parsing, correctness checks, and JSON writing are outside the timed interval.

Compile [`benchmarks/harness/scalar_runner.c`](../../harness/scalar_runner.c) with `-DBENCHMARK_FUNCTION=fibonacci`. [`benchmarks/run_scalar.py`](../../run_scalar.py) appends one JSON Lines record per workload case using [`benchmarks/results.schema.json`](../../results.schema.json). Scalar records use `input_length: null` and put `n` in `input_value`.

[`build_scalar.py`](../../build_scalar.py) provides the standalone build recipe for all nine languages. [`verify_scalar.py`](../../verify_scalar.py) checks every valid input from 0 through 92 against an independent fast-doubling oracle, supplements them with invalid and signed-width boundary inputs, and exercises the JSONL recording flow through the native C ABI. The loop stops after forming `F(n)` so the `F(92)` case never evaluates the unrepresentable `F(93)`. The report identifies the host and source hashes; it does not claim that every platform has been tested.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/f/fibonacci.c`](../../../c/f/fibonacci.c) | Independent portable implementation; TheAlgorithms C reference below |
| C3 | [`c3/f/fibonacci.c3`](../../../c3/f/fibonacci.c3) | Local port |
| C++ | [`cpp/f/fibonacci.cpp`](../../../cpp/f/fibonacci.cpp) | Independent portable implementation; TheAlgorithms C++ reference below |
| Elisa | [`elisa/f/fibonacci.elisa`](../../../elisa/f/fibonacci.elisa) | Local port for the custom Elisa compiler |
| Nim | [`nim/f/fibonacci.nim`](../../../nim/f/fibonacci.nim) | Local port |
| Odin | [`odin/f/fibonacci.odin`](../../../odin/f/fibonacci.odin) | Local port |
| Rust | [`rust/f/fibonacci.rs`](../../../rust/f/fibonacci.rs) | Independent portable implementation; TheAlgorithms Rust reference below |
| V | [`v/f/fibonacci.v`](../../../v/f/fibonacci.v) | Local port |
| Zig | [`zig/f/fibonacci.zig`](../../../zig/f/fibonacci.zig) | Local port |

All local code was written independently under the shared contract.

## TheAlgorithms references

- [C LeetCode `509.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/509.c) computes zero-based Fibonacci values with `F(0)=0` and `F(1)=1`.

- [C `fibonacci.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/fibonacci.c)
- [C++ `fibonacci.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/fibonacci.cpp)
- [Rust `fibonacci.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/fibonacci.rs)
