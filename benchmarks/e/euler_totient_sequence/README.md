# Euler Totient Sequence

Compute `φ(1)` through `φ(n)` by factoring each value independently and applying the distinct-prime formula. This follows the method used by TheAlgorithms/C-Sharp `EulerTotientSequence`.

## Contract

- Input is a signed 64-bit integer in `1..=80`; values outside the range return `-1`.
- Return `φ(1), φ(2), ..., φ(n)` as comma-separated ASCII decimal bytes, in order. The return value is the number of bytes written.
- Insufficient output capacity returns `-2`.

This is a repeated-factorization sequence. [`compute_totient`](../compute_totient/README.md) uses a sieve, and [`totients_linear_sieve`](../totients_linear_sieve/README.md) uses the linear sieve recurrence.

## Workload

[`workload.json`](workload.json) shares the sequence contract and bounded workload through `n = 80`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/euler_totient_sequence.c`](../../../c/e/euler_totient_sequence.c) |
| C3 | [`c3/e/euler_totient_sequence.c3`](../../../c3/e/euler_totient_sequence.c3) |
| C++ | [`cpp/e/euler_totient_sequence.cpp`](../../../cpp/e/euler_totient_sequence.cpp) |
| Elisa | [`elisa/e/euler_totient_sequence.elisa`](../../../elisa/e/euler_totient_sequence.elisa) |
| Nim | [`nim/e/euler_totient_sequence.nim`](../../../nim/e/euler_totient_sequence.nim) |
| Odin | [`odin/e/euler_totient_sequence.odin`](../../../odin/e/euler_totient_sequence.odin) |
| Rust | [`rust/e/euler_totient_sequence.rs`](../../../rust/e/euler_totient_sequence.rs) |
| V | [`v/e/euler_totient_sequence.v`](../../../v/e/euler_totient_sequence.v) |
| Zig | [`zig/e/euler_totient_sequence.zig`](../../../zig/e/euler_totient_sequence.zig) |

## Upstream source

[TheAlgorithms/C-Sharp `EulerTotientSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/EulerTotientSequence.cs)

Build with `python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm euler_totient_sequence --language c` and record with `benchmarks/run_i64_scalar_bytes_output.py`.
