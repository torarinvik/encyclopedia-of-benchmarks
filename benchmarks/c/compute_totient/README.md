# Compute Totient

This benchmark ports TheAlgorithms/Rust `compute_totient`, which computes Euler's totient values from 1 through an inclusive limit.

## Contract

- The signed 64-bit input `n` is in `1..=80`. Values outside this range return `-1`.
- For valid `n`, the function produces `phi(1), phi(2), ..., phi(n)` in order, encoded as comma-separated ASCII decimal bytes. The return value is the number of bytes written.
- A null output pointer or insufficient output capacity returns `-2`.
- The implementation initializes `phi[i] = i`, identifies primes from unchanged entries, sets each prime's totient to `p - 1`, then updates its multiples starting at `2p`, matching the upstream sieve.

The upstream function accepts `i32` and returns a vector. The benchmark uses a bounded `1..=80` input domain and byte-output encoding so all nine implementations share the repository's C ABI. The upstream function's `n = 0` behavior is not included because slicing the result from index 1 panics for that input.

## Workload

[`workload.json`](workload.json) includes the published examples for `n = 4`, `7`, and `12`, additional small and larger inputs through 80, and invalid values. The output preserves the upstream vector order. Workload measurements use the shared signed scalar byte-output runner with two warmup rounds, nine samples, and 100 calls per sample.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/compute_totient.c`](../../../c/c/compute_totient.c) |
| C3 | [`c3/c/compute_totient.c3`](../../../c3/c/compute_totient.c3) |
| C++ | [`cpp/c/compute_totient.cpp`](../../../cpp/c/compute_totient.cpp) |
| Elisa | [`elisa/c/compute_totient.elisa`](../../../elisa/c/compute_totient.elisa) |
| Nim | [`nim/c/compute_totient.nim`](../../../nim/c/compute_totient.nim) |
| Odin | [`odin/c/compute_totient.odin`](../../../odin/c/compute_totient.odin) |
| Rust | [`rust/c/compute_totient.rs`](../../../rust/c/compute_totient.rs) |
| V | [`v/c/compute_totient.v`](../../../v/c/compute_totient.v) |
| Zig | [`zig/c/compute_totient.zig`](../../../zig/c/compute_totient.zig) |

## Upstream source

- [TheAlgorithms/Rust `compute_totient.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/number_theory/compute_totient.rs)

Build with the `i64_scalar_bytes_output` ABI family and record with `benchmarks/run_i64_scalar_bytes_output.py`.
