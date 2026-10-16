# Recursive integer partitions

This benchmark follows the pinned Julia `partitions_recursive` implementation. It counts unordered representations of `n` as a sum of positive integers; summand order does not create a new partition. The Julia source defines `p(0)=1`, and its example gives `p(10)=42`.

## Contract

- The scalar input is `n` in `0..=100`.
- The result is the exact signed 64-bit partition count. Examples include `p(0)=1`, `p(5)=7`, and `p(100)=79270`.
- Inputs outside the range return `INT64_MIN`; the Julia source throws for negative values, while the upper bound keeps the result representable in signed 64-bit.

The source sums `P_k(n)` for `k=1..n` and uses `P_k(n)=P_{k-1}(n-1)+P_k(n-k)`, with base cases for `P_0(0)`, one-part partitions, and `k=n`. The benchmark ports memoize that recursion per call to bound repeated work; the recurrence and result are unchanged. The zero case is handled directly as the source does.

This is distinct from [`integer_partition`](../i/integer_partition/README.md), which ports a two-dimensional iterative table from Python and Rust and excludes zero.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/partitions.c`](../../../c/p/partitions.c) |
| C3 | [`c3/p/partitions.c3`](../../../c3/p/partitions.c3) |
| C++ | [`cpp/p/partitions.cpp`](../../../cpp/p/partitions.cpp) |
| Elisa | [`elisa/p/partitions.elisa`](../../../elisa/p/partitions.elisa) |
| Nim | [`nim/p/partitions.nim`](../../../nim/p/partitions.nim) |
| Odin | [`odin/p/partitions.odin`](../../../odin/p/partitions.odin) |
| Rust | [`rust/p/partitions.rs`](../../../rust/p/partitions.rs) |
| V | [`v/p/partitions.v`](../../../v/p/partitions.v) |
| Zig | [`zig/p/partitions.zig`](../../../zig/p/partitions.zig) |

## Workload and recording

[`workload.json`](workload.json) covers zero, representative counts through the maximum supported input, and invalid-input sentinels. The runtime oracle is [`partitions_oracle.py`](../../partitions_oracle.py); the shared scalar runner checks workload expectations before recording. Build with the scalar ABI and record using `benchmarks/run_scalar.py`.

## Pinned source

- [TheAlgorithms/Julia `partitions.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/partitions.jl)
