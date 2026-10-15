# Weird number

This benchmark checks whether an integer is abundant but cannot be written as a sum of a subset of its positive proper divisors.

## Contract

- The input is a signed 64-bit integer from `0` through `512`.
- Return `1` exactly when the input is abundant and not semiperfect; return `0` otherwise.
- Inputs outside the range return `-1`.
- For positive inputs, the implementation finds proper divisors, sums them, and uses 0/1 subset-sum to determine whether they can sum to the input. Divisors are processed once, and the reachable-sum table is updated in descending order.
- The source explicitly returns `false` for zero. The ports preserve that result. The bound keeps the subset-sum work and storage small.

The pinned Python function `weird(number)` returns `abundant(number) and not semi_perfect(number)`. Its `factors` helper begins with 1, which makes its abundant and semiperfect helpers both return true for zero; their conjunction therefore makes `weird(0)` false. For positive inputs, the factor list contains the positive proper divisors.

## Inspected upstream source

- [Python — `weird_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/weird_number.py)

Build and record with the `scalar` ABI family. Implementations are in `w/` in all nine language directories.
