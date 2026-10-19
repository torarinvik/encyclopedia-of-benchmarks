# Shootout fib2

This benchmark ports the pinned lac-dcc Shootout `fib2` source. The source recursively computes `fib(n-2) + fib(n-1)` and returns `1` whenever `n < 2`; therefore its output is the one-based sequence `1, 1, 2, 3, 5, ...`, or the conventional Fibonacci value `F(n+1)`.

## Contract

- Accept `n` from 0 through 30 and return the exact source result.
- Return `-1` for negative inputs and inputs above 30. This keeps the uncached recursion bounded and avoids the source's unsafe conversion of negative command-line values to `unsigned long`.
- Preserve the recursive implementation without memoization. The largest result is 2,178,309, which fits in the signed 64-bit ABI.

[`workload.json`](workload.json) covers the base cases, representative indices, the bound, and invalid inputs. The independent oracle is [`benchmarks/fib2_oracle.py`](../../fib2_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/f/fib2.c`](../../../c/f/fib2.c) |
| C3 | [`c3/f/fib2.c3`](../../../c3/f/fib2.c3) |
| C++ | [`cpp/f/fib2.cpp`](../../../cpp/f/fib2.cpp) |
| Elisa | [`elisa/f/fib2.elisa`](../../../elisa/f/fib2.elisa) |
| Nim | [`nim/f/fib2.nim`](../../../nim/f/fib2.nim) |
| Odin | [`odin/f/fib2.odin`](../../../odin/f/fib2.odin) |
| Rust | [`rust/f/fib2.rs`](../../../rust/f/fib2.rs) |
| V | [`v/f/fib2.v`](../../../v/f/fib2.v) |
| Zig | [`zig/f/fib2.zig`](../../../zig/f/fib2.zig) |

## Pinned source

[lac-dcc/Benchmarks `Shootout/fib2/fib2.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/fib2/fib2.c)
