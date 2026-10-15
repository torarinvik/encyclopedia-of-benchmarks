# Twin prime

This benchmark checks whether an input begins a twin-prime pair.

## Contract

- The input is one signed 64-bit integer in `[-4096, 4096]`.
- Return `n + 2` exactly when both `n` and `n + 2` are prime; otherwise return `-1`.
- Inputs outside the documented range return `-1`. This bounded domain keeps `n + 2` safe in the scalar ABI.
- Primality is checked with trial division through the integer square root. Values below 2 are not prime.

Both pinned upstream implementations have the same pair-input behavior. The Java method `getTwinPrime` returns `inputNumber + 2` only when both values pass `PrimeCheck.isPrime`; the Python function `twin_prime` applies the same condition. The benchmark bounds the source's broader integer domain for a portable signed-64 ABI.

## Inspected upstream sources

- [Java — `TwinPrime.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/TwinPrime.java)
- [Python — `twin_prime.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/twin_prime.py)

Build and record with the `scalar` ABI family. Implementations are in `t/` in all nine language directories.
