# Longest Substring Without Repeating Characters

This benchmark returns the length of the longest contiguous substring whose characters are all distinct. It follows the sliding-window problem in [TheAlgorithms/C LeetCode 3](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/3.c), [TheAlgorithms/Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/LongestSubstringWithoutRepeatingCharacters.java), and [TheAlgorithms/JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Sliding-Window/LongestSubstringWithoutRepeatingCharacters.js). The pinned C implementation contains both an O(n) version and a separate brute-force definition with the same function name; this benchmark follows the O(n) version. The Java and JavaScript versions shrink a unique-character window from the left. The pinned C++ candidate URL currently returns 404 and was not used as evidence.

## Contract

- The ABI represents a string as an array of printable ASCII values (32 through 126), with a maximum length of 1,024.
- The result is the length of the longest contiguous substring with no repeated value. Empty input returns 0.
- Invalid values or an overlong input return -2. The input is not modified.
- Runtime is O(n); each port uses a fixed 95-entry last-seen table and O(1) auxiliary space.

LeetCode candidate `3` uses this alphabetic benchmark name because numeric source stems are identifiers in the catalog, not algorithm module names.

Run `python3 benchmarks/verify_longest_substring_without_repeating_characters.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` from the repository root to check all nine ports against exhaustive short strings, randomized inputs, invalid values, maximum-length inputs, and the published workload.

## Inspected upstream sources

- [C — LeetCode `3.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/3.c)
- [Java — `LongestSubstringWithoutRepeatingCharacters.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/slidingwindow/LongestSubstringWithoutRepeatingCharacters.java)
- [JavaScript — `LongestSubstringWithoutRepeatingCharacters.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/Sliding-Window/LongestSubstringWithoutRepeatingCharacters.js)
