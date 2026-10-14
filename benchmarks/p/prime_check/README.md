# Prime check

## Contract

Return `1` for a prime, `0` for an integer below 2 or a composite, and `-1` for positive inputs greater than `2,147,483,647`. Negative signed 64-bit inputs return `0`. This bound keeps the shared trial-division algorithm practical and avoids overflow in square-based loop conditions across all target languages.

The exported C ABI entry point is `int64_t prime_check(int64_t n);`. Implementations test divisors through the square root using `factor <= n / factor`, which avoids multiplying the factor by itself. Even factors are skipped after handling 2.

## Source review and aliases

The pinned `prime_check`, `prime`, `check_prime`, and `is_prime` sources all implement the primality predicate with trial division (one Java source also includes a randomized Fermat variant). Their input types and handling of negative values differ. The shared benchmark standardizes the mathematical definition and a signed 32-bit positive limit; `prime`, `check_prime`, and `is_prime` are cataloged as aliases of `prime_check`.

## Workload and verification

[`workload.json`](workload.json) covers negatives, 0 and 1, small primes and composites, a source example, the largest accepted prime, and out-of-range values. [`verify_scalar.py`](../../verify_scalar.py) checks every input from -1,024 through 10,000, deterministic inputs through the accepted range, known prime/composite boundaries, and signed 64-bit boundaries against Python's integer square-root oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/prime_check.c`](../../../c/p/prime_check.c) |
| C3 | [`c3/p/prime_check.c3`](../../../c3/p/prime_check.c3) |
| C++ | [`cpp/p/prime_check.cpp`](../../../cpp/p/prime_check.cpp) |
| Elisa | [`elisa/p/prime_check.elisa`](../../../elisa/p/prime_check.elisa) |
| Nim | [`nim/p/prime_check.nim`](../../../nim/p/prime_check.nim) |
| Odin | [`odin/p/prime_check.odin`](../../../odin/p/prime_check.odin) |
| Rust | [`rust/p/prime_check.rs`](../../../rust/p/prime_check.rs) |
| V | [`v/p/prime_check.v`](../../../v/p/prime_check.v) |
| Zig | [`zig/p/prime_check.zig`](../../../zig/p/prime_check.zig) |

## TheAlgorithms references

- [Dart `prime_check.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/prime_check.dart)
- [Java `PrimeCheck.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/Prime/PrimeCheck.java)
- [JavaScript `PrimeCheck.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PrimeCheck.js)
- [Julia `prime_check.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/prime_check.jl)
- [MATLAB-Octave `prime_check.m`](https://github.com/TheAlgorithms/MATLAB-Octave/blob/e150b77ad256de46c1ce3815c3d7945ac4fc28dc/algorithms/maths/prime_check.m)
- [Python `prime_check.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/prime_check.py)
- [Rust `prime_check.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/prime_check.rs)
- [C `prime.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/math/prime.c) and [F-Sharp `Prime.fs`](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Math/Prime.fs)
- [R `prime.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/prime.r)
- [C++ `check_prime.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/check_prime.cpp), [additional C++ repository copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/check_prime.cpp), and [PHP `CheckPrime.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/CheckPrime.php)
- [Kotlin `isPrime.kt`](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/dynamicProgramming/isPrime.kt) and [Lua `is_prime.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/prime/is_prime.lua)
