# First N Primes

## Contract

Return the first `n` prime numbers in ascending order, encoded as comma-separated ASCII decimal bytes. The C ABI accepts a signed 64-bit count from 0 through 20. Negative or larger counts return `-1`. If the output buffer cannot hold the complete encoding, the function returns `-2`; otherwise it returns the number of bytes written. A count of zero produces an empty result.

The local implementations test consecutive candidates by trial division through the square root and stop after finding `n` primes. This matches the generator operation in the pinned TypeScript source and the compile-time first-primes helper in the Zig source. It is distinct from [`prime_numbers`](../../p/prime_numbers/README.md), which takes an inclusive numeric limit.

## Workload and measurement

[`workload.json`](workload.json) covers empty and short sequences, representative counts, the maximum supported count, and invalid boundaries. The scalar byte-output runner checks results before timing and hashes each returned byte sequence. It runs two warmup batches and records nine samples of 100 calls per case.

[`benchmarks/verify_first_n_primes.py`](../../verify_first_n_primes.py) exhausts all supported counts, checks exact and insufficient output capacities, and tests signed boundary inputs against an independent trial-division oracle. The verification report records the host and source hashes; it does not claim that every platform has been tested.

## Implementations

| Language | Source | Origin |
| --- | --- | --- |
| C | [`c/p/first_n_primes.c`](../../../c/f/first_n_primes.c) | Portable local implementation |
| C3 | [`c3/p/first_n_primes.c3`](../../../c3/f/first_n_primes.c3) | Portable local implementation |
| C++ | [`cpp/p/first_n_primes.cpp`](../../../cpp/f/first_n_primes.cpp) | Portable local implementation |
| Elisa | [`elisa/p/first_n_primes.elisa`](../../../elisa/f/first_n_primes.elisa) | Local implementation for the custom Elisa compiler |
| Nim | [`nim/p/first_n_primes.nim`](../../../nim/f/first_n_primes.nim) | Portable local implementation |
| Odin | [`odin/p/first_n_primes.odin`](../../../odin/f/first_n_primes.odin) | Portable local implementation |
| Rust | [`rust/p/first_n_primes.rs`](../../../rust/f/first_n_primes.rs) | Portable local implementation |
| V | [`v/p/first_n_primes.v`](../../../v/f/first_n_primes.v) | Portable local implementation |
| Zig | [`zig/p/first_n_primes.zig`](../../../zig/f/first_n_primes.zig) | Local implementation; upstream Zig helper below |

## TheAlgorithms references

- [TypeScript `primes.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/primes.ts)
- [Zig `primes.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/primes.zig)
