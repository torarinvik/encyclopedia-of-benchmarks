# Smallest prime factor

This benchmark preserves the `smallest_prime_factor` method from the pinned Python `primelib.py` bundle. It is a separate scalar routine from `greatest_prime_factor` and from the full factor-list operations.

## Contract

The `i64_array_scalar` ABI accepts exactly one signed 64-bit integer, `[n]`, with `2 <= n <= 1,000,005`. Return the smallest prime that divides `n`; a prime input returns itself. Inputs outside this benchmark range, malformed framing, or an extra value return `-1`.

The source calls `prime_factorization(n)` and returns the minimum of its ascending prime factor list. For composite values, that helper searches candidate factors from 2 upward and repeatedly divides the quotient. The bounded contract excludes the source helper's `[0]` and `[1]` sentinel factor lists.

## Pinned source

The source is [`smallest_prime_factor`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/primelib.py#L252-L286) in TheAlgorithms/Python commit `e1a2a8b016001309a73d5fec4818c35cca139795`. The result matches the first divisor found by ascending trial division; the input bound keeps the search practical.

See the [workload](workload.json) and [oracle](../../smallest_prime_factor_oracle.py).
