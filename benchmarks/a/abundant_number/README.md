# Abundant number

Determine whether a positive integer is abundant: the sum of its positive proper divisors is greater than the integer.

## Contract

- Input is a signed 64-bit integer from 1 through 100,000,000.
- Return 1 when the proper-divisor sum is greater than the input, and 0 otherwise.
- Inputs outside the stated range return -1.
- The implementations scan divisor pairs from 2 while the divisor is at most n divided by itself. A square root is included only once, and the scan exits as soon as the sum exceeds n.

The upper bound keeps the pinned Java implementation's signed 32-bit divisor sums in range: for `n <= 100,000,000`, the divisor sum is at most `n * H_n < 1.94 billion`, and `2 * n` is at most 200 million. This makes both public Java decision methods agree with the mathematical proper-divisor predicate across the benchmark range. The contract gives zero and negative inputs a deterministic sentinel result; the Java source throws for nonpositive integers.

## Workload and verification

[workload.json](workload.json) covers invalid bounds, one, primes, perfect numbers, the first abundant number, an odd abundant number, and a large abundant input. [verify_scalar.py](../../verify_scalar.py) checks the benchmark against an independent multiplicative divisor-sum oracle and validates workload recording in all nine languages.

## Reviewed TheAlgorithms sources

- [Java AbundantNumber.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AbundantNumber.java) classifies using the sum of all divisors, including the number itself, and compares it with twice the number.
- [Python abundant_numbers.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/abundant_numbers.py) sums positive proper divisors by scanning factor pairs.

## Implementations

The nine portable implementations use the shared scalar ABI and live in each language's a folder.
