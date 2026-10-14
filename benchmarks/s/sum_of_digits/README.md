# Sum of digits

This benchmark sums the decimal digits of the magnitude of an integer. The C++ source explicitly ignores the negative sign, and the Rust source uses an unsigned magnitude so the minimum signed integer is handled safely. The shared contract follows the iterative decimal-remainder algorithm and defines behavior at the signed 32-bit boundaries.

## Contract

- Input is a signed 32-bit integer passed through the scalar signed 64-bit ABI.
- The negative sign is ignored; zero has digit sum zero.
- Inputs outside `[-2,147,483,648, 2,147,483,647]` return `-1`.
- The output is the sum of the decimal digits of the input's absolute value.
- The nine implementations use division and remainder only; no architecture-specific operations or allocation are involved.

## Workload and verification

[`workload.json`](workload.json) includes positive and negative values, powers of ten, and both signed 32-bit boundaries. [`verify_sum_of_digits.py`](../../verify_sum_of_digits.py) compares every port with a decimal-string oracle over all inputs from `-10,000` through `10,000`, boundary neighbors, and deterministic random values.

## Reviewed TheAlgorithms sources

- [C++ `sum_of_digits.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/sum_of_digits.cpp) — iterative quotient/remainder loop; the source ignores negative signs.
- [Rust `sum_of_digits.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/sum_of_digits.rs) — iterative signed-integer variant using an unsigned magnitude.

The Java source contains iterative, recursive, and character-based variants. The C-Sharp source accepts only nonnegative input. The common benchmark selects the iterative decimal algorithm and makes negative-input behavior explicit.
