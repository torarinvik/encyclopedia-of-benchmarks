# Modular exponentiation

Modular exponentiation computes `base^exponent mod modulus` using repeated squaring. The pinned C++ and R sources use binary exponentiation; C# uses repeated multiplication. This benchmark standardizes their result and input domain and uses binary exponentiation in each portable port.

## Contract

Input is a three-element signed 64-bit array `[base, exponent, modulus]`. The base is a signed 32-bit integer, the exponent is a nonnegative signed 32-bit integer, and the modulus is a positive signed 32-bit integer. The result is the mathematical residue in `[0, modulus)`, including for negative bases. Invalid input returns `-1`.

The implementation normalizes the base once, then performs O(log exponent) square-and-multiply steps. Since all residues are less than `2^31`, each intermediate product fits signed 64-bit. No architecture-specific instructions are used.

## Reproduce

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm modular_exponentiation --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm modular_exponentiation
python3 benchmarks/verify_modular_exponentiation.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1
```

The verifier uses Python’s three-argument `pow` as an independent oracle across exhaustive small combinations, random values, signed boundaries, malformed inputs, and the published workload. The pinned C++ implementation does not validate a zero modulus, and the C# implementation iterates once per exponent; the shared contract rejects nonpositive moduli and fixes the algorithm to binary exponentiation for comparable scaling.

Upstream references: [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/modular_exponentiation.cpp), [C#](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/ModularExponentiation.cs), and [R](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/modular_exponentiation.r).
