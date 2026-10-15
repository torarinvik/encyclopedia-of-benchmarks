# Chinese remainder theorem

The Chinese remainder theorem combines congruences with pairwise-coprime moduli into one least nonnegative solution. Input values are flattened as `[remainder_0, modulus_0, remainder_1, modulus_1, ...]`.

## Contract

- Accept one to four congruences (two to eight signed 64-bit input values).
- Each modulus must be from 2 through 1,000; each remainder must be in `[0, modulus)`; the moduli must be pairwise coprime.
- Return the unique solution in `[0, product(moduli))`. Invalid inputs return `-1`.
- The implementation combines congruences incrementally using modular inverses from the extended Euclidean algorithm. The four-equation and modulus limits keep all intermediate values within signed 64-bit range.

## Reviewed TheAlgorithms sources

The inspected C#, Java, Rust, and Zig sources use the product-of-moduli CRT formula; Rust returns no solution when an inverse does not exist, while C# validates the pairwise-coprime precondition. Python computes a formula for two moduli but does not validate that precondition, and one of its non-coprime examples does not satisfy the stated congruences. The shared contract follows the pairwise-coprime theorem and returns an explicit invalid-input sentinel.

- [C# — `ChineseRemainderTheorem.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/ModularArithmetic/ChineseRemainderTheorem.cs)
- [Dart — `chinese_remainder_theorem.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/other/chinese_remainder_theorem.dart)
- [Java — `ChineseRemainderTheorem.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/ChineseRemainderTheorem.java)
- [Python — `chinese_remainder_theorem.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/chinese_remainder_theorem.py)
- [Rust — `chinese_remainder_theorem.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74a4c939ec5163648458a8c2b46fd4c/src/math/chinese_remainder_theorem.rs)
- [Zig — `chineseRemainderTheorem.zig`](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/math/chineseRemainderTheorem.zig)

## Workload

`workload.json` covers valid one- through four-equation systems, the Python example, non-coprime and malformed inputs, and out-of-range remainders. Build and record with the `i64_array_scalar` ABI family. The nine portable source files are under `c/` in each target language folder.
