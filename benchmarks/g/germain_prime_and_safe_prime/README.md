# Germain prime and safe prime

This package exposes the two predicates in the pinned Java class through a small selector-based ABI.

## Contract

- The `i64_array_scalar` ABI receives `[number, selector]`.
- `selector = 0` checks whether `number` is a Germain prime; `selector = 1` checks whether it is a safe prime.
- `number` must be in `[1, 1,000,000]`. A match returns `1`, a nonmatch returns `0`, and an invalid array, selector, or number returns `-1`.
- Germain prime: `is_prime(number) && is_prime(2 * number + 1)`.
- Safe prime: `((number - 1) % 2 == 0) && is_prime(number) && is_prime((number - 1) / 2)`.

## Source behavior

The pinned Java class provides `isGermainPrime` and `isSafePrime`, both of which reject inputs below 1 and delegate primality to `PrimeCheck.isPrime`. That helper handles 2 directly, rejects values below 2 and even values, then tests odd divisors through the square root. The benchmark preserves these predicates and their short-circuit order. The `1,000,000` bound keeps `2 * number + 1` inside the source's signed 32-bit range. The selector only combines the two source methods into one portable ABI.

## Workload and build

[`workload.json`](workload.json) covers both selectors, prime and composite cases, source boundaries, and malformed input arrays.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm germain_prime_and_safe_prime --language c
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/g/germain_prime_and_safe_prime/c/build.json
```

The nine implementations are in `c/g/germain_prime_and_safe_prime.c`, `c3/g/germain_prime_and_safe_prime.c3`, `cpp/g/germain_prime_and_safe_prime.cpp`, `elisa/g/germain_prime_and_safe_prime.elisa`, `nim/g/germain_prime_and_safe_prime.nim`, `odin/g/germain_prime_and_safe_prime.odin`, `rust/g/germain_prime_and_safe_prime.rs`, `v/g/germain_prime_and_safe_prime.v`, and `zig/g/germain_prime_and_safe_prime.zig`.

## TheAlgorithms references

- [Java `GermainPrimeAndSafePrime.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/GermainPrimeAndSafePrime.java)
- [Java `PrimeCheck.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Prime/PrimeCheck.java)
