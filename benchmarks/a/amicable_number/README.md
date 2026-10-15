# Amicable Number

Two distinct positive integers `a` and `b` are amicable when the proper divisors of `a` sum to `b` and the proper divisors of `b` sum to `a`. For example, `(220, 284)` is amicable.

## Contract

- Inputs are two unsigned 64-bit values in the range `1..=1,000,000,000`.
- The function returns `1` for an amicable pair and `0` otherwise.
- Equal inputs return `0`, even when the value is a perfect number. The mathematical definition requires two distinct numbers.
- An input outside the supported range returns `-1`.
- Each implementation sums proper divisors with a portable divisor-pair scan bounded by `divisor <= number / divisor`; no architecture-specific operations are used.

## Workload and verification

[`workload.json`](workload.json) covers known amicable pairs, reversals, non-pairs, equal inputs, zero, negative and out-of-range inputs, and the upper bound. [`verify_binary_scalar.py`](../../verify_binary_scalar.py) checks the ports against a multiplicative divisor-sum oracle, independently of their divisor-pair scan, with exhaustive small pairs, known pairs, deterministic random values, and boundary combinations.

## Reviewed TheAlgorithms source

- [Java `AmicableNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/AmicableNumber.java) — exposes a pair predicate and a range enumerator; the predicate recursively sums proper divisors.
- [C# `AmicableNumbersChecker.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Numeric/AmicableNumbersChecker.cs), [Dart `amicable_numbers.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/amicable_numbers.dart), and [R `amicable_numbers.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/mathematics/amicable_numbers.r) expose the same pair-predicate operation.
- The two pinned C++ [`check_amicable_pair.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/check_amicable_pair.cpp) sources ([additional repository copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/math/check_amicable_pair.cpp)) compute reciprocal proper-divisor sums and are aliases of this benchmark.

The source documentation defines amicable numbers as distinct, but the Java, C#, and C++ pair predicates do not reject equal perfect numbers. The shared contract follows the documented mathematical definition and handles equal inputs explicitly. The Java range enumeration method is a separate operation, benchmarked under [`amicable_pairs_below`](../amicable_pairs_below/README.md).
