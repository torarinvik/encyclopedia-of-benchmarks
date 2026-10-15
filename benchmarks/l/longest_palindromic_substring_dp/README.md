# Longest Palindromic Substring by Dynamic Programming

This benchmark preserves the gap-based dynamic-programming method in TheAlgorithms/Java's `LongestPalindromicSubstring.lps`. It fills a boolean table from short gaps to long gaps and returns one maximum palindrome.

## Contract

- Input is a nonempty array of 1–1,000 ASCII letters or digits.
- Return the palindrome's byte length and write its bytes to the caller's output buffer, without a NUL terminator.
- When multiple longest palindromes exist, return the rightmost one. This matches the source's gap-then-start iteration and update behavior.
- Invalid input returns `-1`. Insufficient output capacity returns `-2` without writing.
- Time and auxiliary space are both `O(n²)`.

[`workload.json`](workload.json) covers empty and invalid inputs, odd and even palindromes, a tie with different palindrome contents, and the maximum input length. The byte-output runner's independent dynamic-programming oracle applies the same rightmost tie rule.

Build with the `i64_array_bytes_output` ABI:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm longest_palindromic_substring_dp --language rust
```

The sibling [`longest_palindromic_substring`](../longest_palindromic_substring/README.md) benchmark preserves the distinct center-expansion method and its leftmost tie rule.

## Upstream reference

- [TheAlgorithms/Java `LongestPalindromicSubstring.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/LongestPalindromicSubstring.java)
