# Factorial Trailing Zeroes

Count the decimal zeroes at the end of `n!`. Each trailing zero requires a factor pair `(2, 5)`, and factorials contain more factors of two than five, so the result is the total number of factors of five in `1..n`.

## Contract

- Inputs from `0` through `1,000,000,000` return the trailing-zero count. Values outside that range return `-1`.
- Repeatedly divide `n` by five and add each quotient. This counts factors from `5`, `25`, `125`, and higher powers without constructing the factorial.
- Time is O(log₅ n) and auxiliary space is O(1).

## Implementations

All nine target languages use the quotient-sum method with the same signed 64-bit scalar ABI. The workload includes values immediately below and at powers of five, a large valid input, and signed-width errors. See [workload.json](workload.json) and [verify_scalar.py](../../verify_scalar.py).

## Reviewed TheAlgorithms sources

- [C `factorial_trailing_zeroes.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/factorial_trailing_zeroes.c) counts `n / 5^i` using a floating-point power function.
- [C++ `count_of_trailing_ciphers_in_factorial_n.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/bit_manipulation/count_of_trailing_ciphers_in_factorial_n.cpp) sums quotients by powers of five; the additional C++ repository contains the same candidate.

The Python candidate named `trailing_zeroes` counts zero digits at the end of an integer itself, so it has a different input contract and is not included here.
