# Fibonacci range sum

## Contract

Return the inclusive sum `F(start) + F(start + 1) + ... + F(end)`, where `F(0) = 0`, `F(1) = 1`, and `F(k) = F(k - 1) + F(k - 2)`. The exported function is:

```c
int64_t fibonacci_sum(uint64_t start, uint64_t end);
```

Inputs are unsigned 64-bit integers. Valid ranges satisfy `0 <= start <= end <= 90`; invalid ranges return `-1`. The largest valid result is `F(92) - 1 = 7540113804746346428`, which fits in signed 64-bit. The implementation uses the identity `sum(F(start)..F(end)) = F(end + 2) - F(start + 1)` and an iterative Fibonacci recurrence.

The pinned C++ source exposes `fiboSum(n, m)` and uses a matrix recurrence to compute the same inclusive range. Both pinned C++ repository copies have matching semantics. Their `result(n)` helper subtracts one from `F(n)`, and the subtraction in `fiboSum` cancels those offsets. The shared contract bounds inputs so the result is exact and representable at the ABI boundary.

## Workload

[`workload.json`](workload.json) includes singleton and multi-term ranges, a range beginning at zero, the largest supported endpoint, reversed endpoints, and an endpoint above the supported bound. The benchmark uses the shared `binary_scalar` ABI family: two unsigned 64-bit inputs and one signed 64-bit result.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fibonacci_sum.c`](../../../c/f/fibonacci_sum.c) |
| C3 | [`c3/f/fibonacci_sum.c3`](../../../c3/f/fibonacci_sum.c3) |
| Elisa | [`elisa/f/fibonacci_sum.elisa`](../../../elisa/f/fibonacci_sum.elisa) |
| Nim | [`nim/f/fibonacci_sum.nim`](../../../nim/f/fibonacci_sum.nim) |
| Odin | [`odin/f/fibonacci_sum.odin`](../../../odin/f/fibonacci_sum.odin) |
| Rust | [`rust/f/fibonacci_sum.rs`](../../../rust/f/fibonacci_sum.rs) |
| V | [`v/f/fibonacci_sum.v`](../../../v/f/fibonacci_sum.v) |
| Zig | [`zig/f/fibonacci_sum.zig`](../../../zig/f/fibonacci_sum.zig) |

## Pinned sources

- [C++ `fibonacci_sum.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/fibonacci_sum.cpp)
- [C++ additional repository `fibonacci_sum.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/fibonacci_sum.cpp)
