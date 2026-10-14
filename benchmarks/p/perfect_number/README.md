# Perfect number

## Contract

Return `1` when a signed integer equals the sum of its positive proper divisors, and `0` otherwise. Inputs from `2` through `1,000,000,000,000` are in range; larger positive inputs return `-1`. Values below `2` return `0`. The upper bound keeps the divisor-pair scan practical while leaving room for inputs much larger than the source examples.

The exported C ABI entry point is `int64_t perfect_number(int64_t n);`. For in-range `n > 1`, start the proper-divisor sum at `1`, scan factors while `factor <= n / factor`, and add both members of each divisor pair. Add a square root only once. The division-based loop condition avoids multiplication overflow. The sum may return early once it exceeds `n`, since all remaining divisors are positive.

## Source review

The pinned Dart, Java, JavaScript, Julia, PHP, Python, R, and TypeScript sources define a perfect number as a positive integer equal to its proper-divisor sum. The C-Sharp `perfect_number_checker` and Go `perfectnumber` sources implement the same predicate and are cataloged as aliases. Their divisor scans range from direct enumeration to paired divisors up to the square root. The two Python files duplicate the same predicate under the same function name; the Java file also contains both a direct and a paired-divisor method. The benchmark uses the shared mathematical predicate and the paired-divisor method for a bounded signed 64-bit domain.

## Workload and verification

[`workload.json`](workload.json) covers signed and lower-bound inputs, known perfect numbers and their neighbors, a square, a prime, and the supported-range boundary. [`verify_scalar.py`](../../verify_scalar.py) checks dense small values, known perfect-number boundaries, deterministic random values, and signed 64-bit boundaries against an independent prime-factorization divisor-sum oracle.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/perfect_number.c`](../../../c/p/perfect_number.c) |
| C3 | [`c3/p/perfect_number.c3`](../../../c3/p/perfect_number.c3) |
| C++ | [`cpp/p/perfect_number.cpp`](../../../cpp/p/perfect_number.cpp) |
| Elisa | [`elisa/p/perfect_number.elisa`](../../../elisa/p/perfect_number.elisa) |
| Nim | [`nim/p/perfect_number.nim`](../../../nim/p/perfect_number.nim) |
| Odin | [`odin/p/perfect_number.odin`](../../../odin/p/perfect_number.odin) |
| Rust | [`rust/p/perfect_number.rs`](../../../rust/p/perfect_number.rs) |
| V | [`v/p/perfect_number.v`](../../../v/p/perfect_number.v) |
| Zig | [`zig/p/perfect_number.zig`](../../../zig/p/perfect_number.zig) |

## TheAlgorithms references

- [Dart `perfect_number.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/perfect_number.dart)
- [C-Sharp `PerfectNumberChecker.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/PerfectNumberChecker.cs)
- [Java `PerfectNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PerfectNumber.java)
- [JavaScript `PerfectNumber.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Maths/PerfectNumber.js)
- [Julia `perfect_number.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/perfect_number.jl)
- [Go `perfectnumber.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/perfectnumber.go)
- [PHP `PerfectNumber.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Maths/PerfectNumber.php)
- [Python `perfect_number.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/perfect_number.py) and [special-numbers copy](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/special_numbers/perfect_number.py)
- [R `perfect_number.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/perfect_number.r)
- [TypeScript `perfect_number.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/perfect_number.ts)
