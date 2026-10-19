# BenchmarkGame recursive benchmark

## Contract

The pinned launcher runs `recursive.c` without options. Its `main` fixes `n=10` and prints five results in order: `Ack(3,n+1)`, recursive floating-point Fibonacci at `28+n`, integer Takeuchi at `(3n,2n,n)`, the source's integer `fib(3)`, and floating-point Takeuchi at `(3.0,2.0,1.0)`. The suite exposes `n` as a scalar in 0..10, with n=10 reproducing the launcher output.

The recursive implementations are direct and uncached. In particular, `fibFP` uses the source base case `n < 2.0 => 1.0`, so its result is the one-based sequence `G(n)=F(n+1)` rather than the conventional `F(0)=0` sequence in [`fibonacci_recursive`](../fibonacci_recursive/README.md). Integer Ackermann and Takeuchi share recurrences with [`ackermann`](../ackermann/README.md) and [`takeuchi`](../takeuchi/README.md), but this workload uses arguments beyond those packages' current profiles. The floating Takeuchi routine and exact combined stdout output are also distinct.

## ABI and workload

The `i64_scalar_bytes_output` entry point accepts `n`, returns the complete five-line ASCII output, and uses -1 for an invalid n and -2 for a null or undersized output buffer. The maximum output is 89 bytes. Measurement uses one call per sample because the naive floating Fibonacci workload grows exponentially.

[workload.json](workload.json) includes the n=0 minimum profile, the exact pinned n=10 launcher output, signed-boundary invalid inputs, and output-buffer errors. [`benchmarkgame_recursive_oracle.py`](../../benchmarkgame_recursive_oracle.py) uses a closed form for Ackermann, iterative one-based Fibonacci, and a memoized Takeuchi recurrence; the language ports keep direct recursion.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/b/benchmarkgame_recursive.c](../../../c/b/benchmarkgame_recursive.c) |
| C3 | [c3/b/benchmarkgame_recursive.c3](../../../c3/b/benchmarkgame_recursive.c3) |
| C++ | [cpp/b/benchmarkgame_recursive.cpp](../../../cpp/b/benchmarkgame_recursive.cpp) |
| Elisa | [elisa/b/benchmarkgame_recursive.elisa](../../../elisa/b/benchmarkgame_recursive.elisa) |
| Nim | [nim/b/benchmarkgame_recursive.nim](../../../nim/b/benchmarkgame_recursive.nim) |
| Odin | [odin/b/benchmarkgame_recursive.odin](../../../odin/b/benchmarkgame_recursive.odin) |
| Rust | [rust/b/benchmarkgame_recursive.rs](../../../rust/b/benchmarkgame_recursive.rs) |
| V | [v/b/benchmarkgame_recursive.v](../../../v/b/benchmarkgame_recursive.v) |
| Zig | [zig/b/benchmarkgame_recursive.zig](../../../zig/b/benchmarkgame_recursive.zig) |

## Pinned source

- [recursive.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/recursive/recursive.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BenchmarkGame/recursive/info.sh)
