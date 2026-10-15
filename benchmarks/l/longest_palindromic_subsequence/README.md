# Longest palindromic subsequence

The longest palindromic subsequence (LPS) is the longest sequence that can be formed by deleting zero or more symbols without changing the order and that reads the same in reverse. This benchmark returns its length for an integer sequence; symbols match only when their signed 64-bit values are equal.

## Contract

- Input is zero to 128 signed 64-bit symbols.
- Return the LPS length; empty input returns zero. Inputs longer than 128 return `-1`.
- The bottom-up interval recurrence takes O(n²) time and uses a one-dimensional 128-entry table, updated along successive diagonals.

## Reviewed TheAlgorithms sources

The pinned Python and JavaScript sources return the LPS length using dynamic programming. C++ computes the LCS of the input and its reverse, then reconstructs a subsequence; R also reconstructs an LPS. The Java source uses recursive string construction. The shared benchmark standardizes on the length result and a bottom-up interval table over exact integer symbols.

- [C++ — `longest_palindromic_subsequence.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/longest_palindromic_subsequence.cpp)
- [C++-1 — `longest_palindromic_subsequence.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/longest_palindromic_subsequence.cpp)
- [Java — `LongestPalindromicSubsequence.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/LongestPalindromicSubsequence.java)
- [JavaScript — `LongestPalindromicSubsequence.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/LongestPalindromicSubsequence.js)
- [Python — `longest_palindromic_subsequence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/longest_palindromic_subsequence.py)
- [R — `longest.palindromic.subsequence.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/string_manipulation/longest.palindromic.subsequence.r)

## Workload

`workload.json` includes empty and singleton sequences, palindrome examples, duplicate-heavy inputs, signed boundaries, and deterministic arrays through the 128-symbol limit. Build and record with the `i64_array_scalar` ABI family. The nine portable source files are under `l/` in each target language folder.
