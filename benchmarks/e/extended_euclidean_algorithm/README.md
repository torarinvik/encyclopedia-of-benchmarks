# Extended Euclidean Algorithm

The extended Euclidean algorithm computes `gcd(a, b)` and coefficients `x` and `y` satisfying Bézout's identity: `a*x + b*y = gcd(a, b)`. The pinned source files expose different result shapes: C-Sharp returns the coefficients before the GCD, Java and Rust return `(gcd, x, y)`, Python returns only the coefficients, and R includes additional recursive, modular-inverse, and Diophantine routines. Their zero and negative input conventions also differ.

## Contract

- Input is exactly two positive signed 32-bit integers, each in `1..=INT32_MAX`. Invalid input returns `-1`.
- The implementation performs iterative extended Euclid and returns `3` on success.
- The output bytes encode `(gcd, coefficient_a, coefficient_b)` as three signed 32-bit two's-complement integers in little-endian byte order. The decoded coefficients satisfy `a*coefficient_a + b*coefficient_b = gcd`.
- Output capacity below 12 bytes returns `-2` without writing any output.

All nine target languages use the same iterative recurrence and fixed-width output encoding. The implementation uses portable integer operations and no processor-specific instructions.

## Workload and verification

[`workload.json`](workload.json) covers coprime and non-coprime pairs, equal and divisibility cases, signed-32-bit boundaries, invalid lengths and values, and maximum-size inputs. [`benchmarks/verify_extended_euclidean_algorithm.py`](../../verify_extended_euclidean_algorithm.py) checks the output against a recursive Bezout-identity oracle, validates `gcd` against Python's `math.gcd`, checks output capacity, and verifies all 17 published cases. All nine implementations passed 2,126 oracle inputs each.

## Upstream sources

- [TheAlgorithms/C-Sharp](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/ModularArithmetic/ExtendedEuclideanAlgorithm.cs)
- [TheAlgorithms/Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ExtendedEuclideanAlgorithm.java)
- [TheAlgorithms/Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/extended_euclidean_algorithm.py)
- [TheAlgorithms/R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/extended_euclidean_algorithm.r)
- [TheAlgorithms/Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/extended_euclidean_algorithm.rs)
