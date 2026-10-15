# Prime factorization

The two pinned C++ sources expose the same operation: for a positive signed `int`, they build a sieve through the input, divide out ascending primes, and print each prime followed by its exponent. Input `1` produces no factor pairs. The sources use fixed global arrays sized for indices through 1,000,005 and do not define useful behavior for zero, negative values, or larger inputs.

## Contract

- Input is a signed 64-bit integer `n` from 1 through 1,000,005. This bound preserves the full valid index range of the pinned sieve array.
- Return each prime-power pair `(prime, exponent)` in ascending prime order. Encode each pair as two unsigned 32-bit integers in little-endian byte order, first the prime and then its positive exponent.
- Return an empty byte sequence for `n = 1`.
- Return `-1` outside the supported input range.
- Return `-2` when the output buffer is too small; do not write any output bytes in that case.
- Return the encoded byte length on success. At this bound, at most seven distinct prime factors occur, so output is at most 56 bytes.

All nine ports use integer trial division and produce the same prime-power factorization as the C++ source. The byte encoding makes the textual line output from the source exact and portable across target architectures.

## Workload

[`workload.json`](workload.json) covers one, primes, repeated powers, mixed composites, the sieve bound, and invalid signed values. Its expected output is stored as hexadecimal for exact byte comparison. The `prime_factorization_pairs_u32le` oracle in `benchmarks/run_i64_scalar_bytes_output.py` independently encodes the expected prime and exponent pairs.

## Upstream sources

- [TheAlgorithms/C-Plus-Plus `prime_factorization.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/prime_factorization.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `prime_factorization.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/prime_factorization.cpp)
