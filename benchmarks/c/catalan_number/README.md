# Catalan number

## Contract

Return the exact zero-based Catalan number `C(n)`, where `C(0) = 1` and `C(n) = sum(C(i) * C(n-i-1))` for `0 <= i < n`. The benchmark accepts signed 64-bit indices from `0` through `35`; other indices return `-1`. `C(35)` fits in a signed 64-bit result, while `C(36)` does not.

The exported C ABI entry point is `int64_t catalan_number(int64_t n);`. Ports use the exact ratio recurrence `C(n) = C(n-1) * (4n-2) / (n+1)`. They reduce numerator and denominator by their greatest common divisor before multiplying; the remaining denominator divides `C(n-1)`, so every intermediate stays within the exact signed 64-bit result range.

## Source review and aliases

The pinned C, C++, C-Sharp, Go, Java, JavaScript, Julia, Nim, Python, R, and Rust sources all cover the standard Catalan sequence, though some return a sequence and others a single indexed value. The benchmark selects the exact scalar `C(n)` contract. `catalan`, `catalan_numbers`, `catalan_sequence`, and `catalannumber` are cataloged as aliases of `catalan_number`. A separate Rust `math/catalan_numbers.rs` source computes values modulo `1,000,000,007`; that modular variant has a different output contract and is excluded from this exact benchmark.

Some upstream factorial formulas overflow or lose precision at indices that fit the benchmark contract. The local ports use one exact recurrence across all nine languages so their measured work implements the same function over the entire declared input range.

## Workload and verification

[`workload.json`](workload.json) covers initial sequence values, known large values, the signed 64-bit result boundary, and invalid indices. [`verify_scalar.py`](../../verify_scalar.py) checks all supported indices, dense invalid indices, deterministic full-width values, and signed boundaries against Python's exact binomial-coefficient oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/catalan_number.c`](../../../c/c/catalan_number.c) |
| C3 | [`c3/c/catalan_number.c3`](../../../c3/c/catalan_number.c3) |
| C++ | [`cpp/c/catalan_number.cpp`](../../../cpp/c/catalan_number.cpp) |
| Elisa | [`elisa/c/catalan_number.elisa`](../../../elisa/c/catalan_number.elisa) |
| Nim | [`nim/c/catalan_number.nim`](../../../nim/c/catalan_number.nim) |
| Odin | [`odin/c/catalan_number.odin`](../../../odin/c/catalan_number.odin) |
| Rust | [`rust/c/catalan_number.rs`](../../../rust/c/catalan_number.rs) |
| V | [`v/c/catalan_number.v`](../../../v/c/catalan_number.v) |
| Zig | [`zig/c/catalan_number.zig`](../../../zig/c/catalan_number.zig) |

## TheAlgorithms references

- C [`catalan.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/catalan.c)
- C++ [`catalan_numbers.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/catalan_numbers.cpp) and [additional C++ repository copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/catalan_numbers.cpp)
- C-Sharp [`CatalanSequence.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Sequences/CatalanSequence.cs)
- Go [`dynamic/catalan.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/dynamic/catalan.go) and [`math/catalan/catalannumber.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/catalan/catalannumber.go)
- Java [`CatalanNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/CatalanNumber.java) and [`CatalanNumbers.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/CatalanNumbers.java)
- JavaScript [`CatalanNumbers.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/CatalanNumbers.js)
- Julia [`catalan_number.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/catalan_number.jl)
- Nim [`catalan_numbers.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/dynamic_programming/catalan_numbers.nim)
- Python [`dynamic_programming/catalan_numbers.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/catalan_numbers.py) and [`maths/special_numbers/catalan_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/catalan_number.py)
- R [`catalan_numbers.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/catalan_numbers.r)
- Rust exact [`dynamic_programming/catalan_numbers.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/catalan_numbers.rs) and modular [`math/catalan_numbers.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/catalan_numbers.rs)
