# Prime factorization

This package captures the direct trial-division strategy used by the pinned Java and TypeScript sources. The two pinned C++ sources compute the same factor pairs with a different strategy: they build a sieve through the input, then divide out ascending primes. That sieve-based strategy is benchmarked separately in [`prime_factorization_sieve`](../prime_factorization_sieve/README.md). The contract here is the shared factor-pair result; zero, negative values, and values above the bound are invalid.

## Contract

- Input is a signed 64-bit integer `n` from 1 through 1,000,005. This bound preserves the full valid index range of the pinned sieve array.
- Return each prime-power pair `(prime, exponent)` in ascending prime order. Encode each pair as two unsigned 32-bit integers in little-endian byte order, first the prime and then its positive exponent.
- Return an empty byte sequence for `n = 1`.
- Return `-1` outside the supported input range.
- Return `-2` when the output buffer is too small; do not write any output bytes in that case.
- Return the encoded byte length on success. At this bound, at most seven distinct prime factors occur, so output is at most 56 bytes.

All nine ports use integer trial division. The byte encoding represents prime-power pairs exactly and portably.

## Workload

[`workload.json`](workload.json) covers one, primes, repeated powers, mixed composites, the sieve bound, and invalid signed values. Its expected output is stored as hexadecimal for exact byte comparison. The `prime_factorization_pairs_u32le` oracle in `benchmarks/run_i64_scalar_bytes_output.py` independently encodes the expected prime and exponent pairs.

## Pinned sources

- [TheAlgorithms/C-Plus-Plus `prime_factorization.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/prime_factorization.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `prime_factorization.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/prime_factorization.cpp)
- [TheAlgorithms/Java `PrimeFactorization.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Prime/PrimeFactorization.java)
- [TheAlgorithms/TypeScript `prime_factorization.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/prime_factorization.ts)
