# Modular division

## Contract

Given `[numerator, denominator, prime_modulus]`, return the least nonnegative residue of `numerator / denominator` modulo `prime_modulus`. This is `numerator * denominator^(prime_modulus-2) mod prime_modulus`, using Fermat's little theorem.

The exported C ABI entry point is:

```c
int64_t modular_division(const int64_t *values, size_t length);
```

The input array must contain exactly three signed 64-bit values. The numerator and denominator must be in `[0, 1,000,000,000,000]`; the modulus must be a prime from 2 through 1,000,000; and the denominator must not be divisible by the modulus. Invalid input returns `-1`. A zero numerator is valid and returns zero.

These bounds keep each product of residues below `10^12`, safely within signed 64-bit range. The modular exponentiation takes at most 20 squaring steps at the maximum modulus. Primality validation uses trial division only through the square root of the bounded modulus.

The two pinned C++ copies take `(numerator, denominator, modulus)` and use Fermat's theorem, assuming a prime modulus and an invertible denominator. The pinned Python function orders its arguments as `(divisor, dividend, modulus)` and uses extended Euclid, allowing any coprime divisor/modulus pair. This benchmark uses the C++ tuple order and prime-modulus domain; the Python implementation matches when called with the denominator first and the numerator second. The C++ test cases `(8, 2, 2)` and `(10, 5, 2)` have no modular inverse and fall outside the valid mathematical domain, despite the source returning zero for them.

## Workload

[`workload.json`](workload.json) covers the pinned examples with valid inverses, Python examples translated to the normalized tuple, large bounded operands, zero numerator, invalid modulus/denominator conditions, and malformed array lengths. It uses the `i64_array_scalar` ABI family.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/modular_division.c`](../../../c/m/modular_division.c) |
| C3 | [`c3/m/modular_division.c3`](../../../c3/m/modular_division.c3) |
| C++ | [`cpp/m/modular_division.cpp`](../../../cpp/m/modular_division.cpp) |
| Elisa | [`elisa/m/modular_division.elisa`](../../../elisa/m/modular_division.elisa) |
| Nim | [`nim/m/modular_division.nim`](../../../nim/m/modular_division.nim) |
| Odin | [`odin/m/modular_division.odin`](../../../odin/m/modular_division.odin) |
| Rust | [`rust/m/modular_division.rs`](../../../rust/m/modular_division.rs) |
| V | [`v/m/modular_division.v`](../../../v/m/modular_division.v) |
| Zig | [`zig/m/modular_division.zig`](../../../zig/m/modular_division.zig) |

## Pinned sources

- [C++ `modular_division.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/modular_division.cpp)
- [C++ additional repository `modular_division.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/modular_division.cpp)
- [Python `modular_division.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/modular_division.py)
