# Number of positive divisors

The two pinned C++ implementations factor the absolute value of one `int` and multiply one plus each prime exponent. Their function returns 1 for zero, even though one source's command-line message describes every nonzero integer as a divisor of zero. This benchmark preserves the function's return value for zero.

## Contract

- Input is an array containing exactly one signed 64-bit integer `n`.
- Accept `n` from -1,000,000,000 through 1,000,000,000. Return the number of positive divisors of `|n|` for nonzero inputs; return 1 for zero, matching the pinned function.
- Return `-1` for values outside that range or for input arrays whose length is not one.
- The bound avoids the pinned C++ implementation's `-INT_MIN` and `i * i` overflow cases.

The result uses the `i64_array_scalar` ABI. All nine ports use integer factorization and return the same divisor count.

## Workload

[`workload.json`](workload.json) covers zero, one, negative values, primes, repeated prime powers, mixed composites, both supported endpoints, invalid values, and invalid input lengths.

## Upstream sources

- [TheAlgorithms/C-Plus-Plus `number_of_positive_divisors.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/number_of_positive_divisors.cpp)
- [TheAlgorithms/C-Plus-Plus-1 `number_of_positive_divisors.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/number_of_positive_divisors.cpp)
