# Fibonacci Dynamic Programming

## Contract

Return the zero-indexed Fibonacci number defined by `F(0) = 0`, `F(1) = 1`, and `F(n) = F(n - 1) + F(n - 2)`. Inputs from `0` through `46` return the exact result as a signed 64-bit integer. Inputs outside that range return `-1`. The bound keeps every value representable in the pinned C source's signed `int` result type; `F(47)` is too large.

The exported C ABI entry point is:

```c
int64_t fibonacci_dp(int64_t n);
```

The pinned C implementation allocates an `n + 2` element table, seeds entries zero and one, fills entries `2..=n` from the prior two entries, and returns the indexed result. The local ports preserve that table recurrence over a fixed, bounded table. The source exits after printing for negative input; the shared contract maps negative and above-bound inputs to `-1` so each implementation remains a scalar call. This package measures tabulation with a table, distinct from [`fibonacci`](../fibonacci/README.md), whose ports keep only two recurrence values.

## Workload and measurement

[`workload.json`](workload.json) covers the initial terms, representative indices, the largest supported input, a negative input, and the first value above the bound. The C11 scalar runner checks each expected result before timing, runs two warmup batches, then records seven samples of 10,000 calls each. Input parsing, correctness checks, and JSON writing are outside the timed interval.

Compile [`benchmarks/harness/scalar_runner.c`](../../harness/scalar_runner.c) with `-DBENCHMARK_FUNCTION=fibonacci_dp`. [`benchmarks/run_scalar.py`](../../run_scalar.py) appends one JSON Lines record per workload case using [`benchmarks/results.schema.json`](../../results.schema.json). Scalar records use `input_length: null` and put `n` in `input_value`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fibonacci_dp.c`](../../../c/f/fibonacci_dp.c) |
| C3 | [`c3/f/fibonacci_dp.c3`](../../../c3/f/fibonacci_dp.c3) |
| C++ | [`cpp/f/fibonacci_dp.cpp`](../../../cpp/f/fibonacci_dp.cpp) |
| Elisa | [`elisa/f/fibonacci_dp.elisa`](../../../elisa/f/fibonacci_dp.elisa) |
| Nim | [`nim/f/fibonacci_dp.nim`](../../../nim/f/fibonacci_dp.nim) |
| Odin | [`odin/f/fibonacci_dp.odin`](../../../odin/f/fibonacci_dp.odin) |
| Rust | [`rust/f/fibonacci_dp.rs`](../../../rust/f/fibonacci_dp.rs) |
| V | [`v/f/fibonacci_dp.v`](../../../v/f/fibonacci_dp.v) |
| Zig | [`zig/f/fibonacci_dp.zig`](../../../zig/f/fibonacci_dp.zig) |

The local ports are independent implementations of the bounded table recurrence.

## TheAlgorithms source

- [C `fibonacci_dp.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/fibonacci_dp.c)
