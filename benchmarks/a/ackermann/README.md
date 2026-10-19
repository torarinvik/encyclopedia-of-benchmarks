# Ackermann Function

Compute the classic two-argument Ackermann function with the direct recursive definition used by the pinned Shootout benchmark:

- A(0, n) = n + 1
- A(m, 0) = A(m - 1, 1) for m > 0
- A(m, n) = A(m - 1, A(m, n - 1)) for m > 0 and n > 0

## Source and contract

The source is [lac-dcc/Benchmarks `ackermann.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ackermann/ackermann.c), pinned at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. Its launcher is [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Shootout/ackermann/info.sh), which supplies no command-line options. The source therefore uses its default `n=8` and prints the result of A(3, 8), which is 2045.

The source's `Ack(m, n)` routine is ported directly. The suite exposes its two arguments through the exported function and supports signed 64-bit inputs in the bounded domain `0 <= m <= 3` and `0 <= n <= 8`; inputs outside that domain return -1. The launcher profile `[3, 8]` is included in the workload. Direct recursion is retained so implementations preserve the source algorithm's work. Benchmark samples make one call each because recursive work grows rapidly.

The bound also keeps every result within signed 64-bit range. It is the suite's bounded profile, not a general-purpose limit for all Ackermann implementations.

## Workload and verification

[workload.json](workload.json) covers all 36 supported input pairs plus signed-boundary and domain-invalid inputs. [`ackermann_oracle.py`](../../ackermann_oracle.py) checks outputs with closed forms for rows zero through three, independently of the ports' recursive implementation. The binary-scalar runner validates every workload result against this oracle, and [`verify_binary_scalar.py`](../../verify_binary_scalar.py) uses the same oracle for its correctness corpus.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/a/ackermann.c](../../../c/a/ackermann.c) |
| C3 | [c3/a/ackermann.c3](../../../c3/a/ackermann.c3) |
| C++ | [cpp/a/ackermann.cpp](../../../cpp/a/ackermann.cpp) |
| Elisa | [elisa/a/ackermann.elisa](../../../elisa/a/ackermann.elisa) |
| Nim | [nim/a/ackermann.nim](../../../nim/a/ackermann.nim) |
| Odin | [odin/a/ackermann.odin](../../../odin/a/ackermann.odin) |
| Rust | [rust/a/ackermann.rs](../../../rust/a/ackermann.rs) |
| V | [v/a/ackermann.v](../../../v/a/ackermann.v) |
| Zig | [zig/a/ackermann.zig](../../../zig/a/ackermann.zig) |

## Additional reference

- [TheAlgorithms Dart recursive Ackermann implementation](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/ackermann.dart) documents the recursive cases and cautions that large arguments quickly exceed practical recursion limits.
