# Prime factorization with a sieve

This benchmark follows the pinned C++ sieve strategy: mark primes through the input, then divide out those primes in ascending order and emit each prime with its exponent. It is a separate benchmark from [`prime_factorization`](../prime_factorization/README.md), whose ports use direct trial division.

## Contract

- Input is a signed 64-bit integer `n` from 1 through 1,000,005.
- Return each prime-power pair `(prime, exponent)` in ascending prime order. Encode each pair as two unsigned 32-bit integers in little-endian byte order, first the prime and then its positive exponent.
- For `n = 1`, return an empty byte sequence.
- Return `-1` outside the supported input range.
- Return `-2` when the output buffer is too small; do not write any output bytes in that case.
- Return the encoded byte length on success. At this bound, at most seven distinct prime factors occur, so output is at most 56 bytes.

The pinned C++ source initializes a Boolean table through `n`, marks composite multiples, and scans the resulting prime list in ascending order. Its loop reads `prime_numbers[i]` before checking whether the remainder is already one, and does not check the vector length. This can read out of bounds for `n = 1` and after the final available prime. The ports define `n = 1` as the empty factorization and use bounds-checked prime scans, preserving the intended factorization and sieve-then-division strategy.

The table is local to each call in every port, avoiding the pinned source's global vectors retaining data across repeated calls.

## Workload and recording

[`workload.json`](workload.json) covers `n = 1`, primes, repeated powers, mixed composites, the sieve bound, and invalid signed values. Its expected output is stored as hexadecimal for exact byte comparison. The `prime_factorization_pairs_u32le` oracle in `benchmarks/run_i64_scalar_bytes_output.py` independently checks each factor-pair encoding.

Build with the `i64_scalar_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm prime_factorization_sieve --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/p/prime_factorization_sieve/rust/build.json
```

The workload uses one repetition per sample because each timed call constructs a sieve through `n`.

## Pinned upstream sources

- [TheAlgorithms/C-Plus-Plus `prime_factorization.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/prime_factorization.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `prime_factorization.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/prime_factorization.cpp)

## Implementations

The nine ports are in the language folders under `p/prime_factorization_sieve` and export `prime_factorization_sieve` through the shared scalar-to-byte-output ABI.
