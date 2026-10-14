# Longest common subsequence

This benchmark returns the length of a longest common subsequence (LCS) of two ASCII sequences. A subsequence preserves element order but may skip elements.

## Contract

- The input packs both sequences as `[left_length, right_length, left_ascii_values..., right_ascii_values...]`.
- Each length is from 0 through 255, each value is from 0 through 127, and the packed array must have exactly `2 + left_length + right_length` values.
- The result is the LCS length. Invalid packed input returns `-1`.
- Each implementation uses one dynamic-programming row with a fixed 256-element buffer and does not modify the input or allocate memory.

The source implementations agree on the LCS recurrence, but some return the subsequence itself while others return its length. This benchmark standardizes the result as the length. The `lcs` filename candidate is reviewed as an alias of this algorithm. Longest common substring is a distinct problem and is not included.

## Inspected upstream sources

- [C-Plus-Plus — `dynamic_programming/longest_common_subsequence.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/dynamic_programming/longest_common_subsequence.cpp)
- [C-Plus-Plus-1 — `dynamic_programming/longest_common_subsequence.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/dynamic_programming/longest_common_subsequence.cpp)
- [Dart — `dynamic_programming/longest_common_subsequence.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/dynamic_programming/longest_common_subsequence.dart)
- [Java — `src/main/java/com/thealgorithms/dynamicprogramming/LongestCommonSubsequence.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/LongestCommonSubsequence.java)
- [JavaScript — `Dynamic-Programming/LongestCommonSubsequence.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Dynamic-Programming/LongestCommonSubsequence.js)
- [Python — `dynamic_programming/longest_common_subsequence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/longest_common_subsequence.py)
- [R — `dynamic_programming/longest_common_subsequence.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/dynamic_programming/longest_common_subsequence.r)
- [Rust — `src/dynamic_programming/longest_common_subsequence.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/dynamic_programming/longest_common_subsequence.rs)
- [C — `dynamic_programming/lcs.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/dynamic_programming/lcs.c)
- [Julia — `src/strings/lcs.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/strings/lcs.jl)
- [Kotlin — `src/main/kotlin/dynamicProgramming/LCS.kt`](https://github.com/TheAlgorithms/Kotlin/blob/b913c1d85c972fd1e679c5d832d6458b21be8fb0/src/main/kotlin/dynamicProgramming/LCS.kt)
- [TypeScript — `dynamic_programming/lcs.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/dynamic_programming/lcs.ts)

## Workload and verification

`workload.json` includes empty sequences, identical and disjoint inputs, repeated bytes, the classic `AGGTAB`/`GXTXAYB` example, ASCII boundaries, maximum-length sequences, and invalid packed inputs. The verifier exhausts all pairs of binary-alphabet sequences through length five, then adds deterministic random, maximum-length, and malformed inputs. It compares each port against a full-table Python dynamic-programming oracle.

```sh
python3 benchmarks/verify_longest_common_subsequence.py --elisa-compiler /absolute/path/to/elisac
```

The benchmark uses the `i64_array_scalar` ABI family. Its implementation files are in the `l/` folder for all nine target languages. The Elisa port uses a loop expression to carry its local DP row and returns the completed row result according to Elisa loop-expression semantics.
