# Count different palindromic subsequences

For a bounded sequence over four symbols, count the distinct nonempty palindromic sequences obtainable by deleting zero or more input positions. Equal resulting symbol sequences are counted once, even when they have multiple index selections. Return the count modulo 1,000,000,007.

## Contract

- Input is `[n, symbols...]`, with `0<=n<=20`, exactly `n+1` signed 64-bit values, and each symbol in `0..3`.
- Empty input sequence returns zero. Invalid length, count, or symbol returns `-1`.
- The result is the number of distinct nonempty palindromic subsequences modulo 1,000,000,007.
- The scalar ABI symbol is `count_different_palindromic_subsequences`.

The primary implementation uses an interval DP. For unequal endpoints it applies inclusion-exclusion to the two shorter intervals. For equal endpoints it doubles the inner count and adjusts according to whether the endpoint symbol occurs zero, one, or at least two times inside. Precomputed next/previous equal-symbol positions make each interval transition constant time. The algorithm takes O(n²) time and O(n²) space. The independent oracle enumerates all nonempty index masks, materializes each resulting sequence, tests it for palindrome symmetry, and deduplicates by sequence value; its bounded O(2ⁿ n) work is structurally separate from the interval recurrence.

## Distinctness and source

[`longest_palindromic_subsequence`](../../l/longest_palindromic_subsequence/README.md) returns a maximum length, while [`eertree`](../../e/eertree/README.md) counts distinct contiguous palindromic substrings. This package counts distinct noncontiguous palindromic sequences. The discovery index was LeetCode's public title page for [Count Different Palindromic Subsequences](https://leetcode.com/problems/count-different-palindromic-subsequences/). Only the title/topic was used; no problem statement, example, test, submission, or site code is incorporated. See [`RIGHTS.md`](RIGHTS.md).

## Workload and oracles

- Workload: [`workload.json`](workload.json)
- Primary interval-DP oracle: [`count_different_palindromic_subsequences_oracle.py`](../../count_different_palindromic_subsequences_oracle.py)
- Independent mask-enumeration oracle: [`count_different_palindromic_subsequences_verifier_oracle.py`](../../count_different_palindromic_subsequences_verifier_oracle.py)
- Static port inventory checker: [`check_inventory.py`](check_inventory.py)

## Ports

The ten implementations are in `c/`, `c3/`, `cpp/`, `elisa/`, `mojo/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/` under the repository's corresponding source trees.
