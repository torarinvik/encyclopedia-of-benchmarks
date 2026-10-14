# Palindrome number

Determine whether a nonnegative decimal integer reads the same from left to right and right to left. The implementation reverses half the digits so intermediate values stay bounded.

## Contract

- Input is a signed 64-bit scalar in the range 0 through 2,147,483,647.
- Return `1` for a palindrome and `0` otherwise.
- Negative and out-of-range inputs return `-1`.
- Zero is a palindrome. Positive values ending in zero are not palindromes.

The pinned C source uses half reversal. Dart and Java use full reversal; local ports use the overflow-safe half-reversal recurrence under this shared contract.

## Workload and verification

[`workload.json`](workload.json) covers zero, one-digit values, odd- and even-length palindromes, trailing zeros, inner zeros, signed 32-bit boundaries, and invalid values. [`verify_scalar.py`](../../verify_scalar.py) includes this algorithm in its independent string-reversal oracle and exhaustive, random, and boundary inputs across all nine languages.

```sh
python3 benchmarks/verify_scalar.py --algorithms palindrome_number --elisa-compiler /absolute/path/to/elisac
```

Build and record with the `scalar` ABI family. Sources are under `p/` in `c/`, `c3/`, `cpp/`, `elisa/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/`.

## Reviewed TheAlgorithms sources

- [C LeetCode `9.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/9.c) reverses half the number and compares the remaining and reversed halves.
- [Dart `palindrome_number.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/palindrome_number.dart) reverses all decimal digits and rejects negative input by throwing.
- [Java `PalindromeNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PalindromeNumber.java) also uses full reversal and rejects negative values.
