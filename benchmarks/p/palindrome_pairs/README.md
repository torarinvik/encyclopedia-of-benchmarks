# Palindrome pairs

Enumerate ordered pairs of distinct input-word indices whose concatenated symbol sequences form a palindrome. This bounded profile uses a small alphabet and allows empty words and duplicate word values; repeated values at different input positions remain separate indices.

## Contract

- Input is `[N,(length,symbols...)*N]`, with `0<=N<=8` and each word length in `0..8`.
- Every symbol is an integer in `0..3`; empty words are valid.
- The exact input length is one count word plus one length word and the symbols for each word. The maximum valid and parseable lengths are 73 and 74 signed 64-bit values.
- Output is one byte per pair, encoding `(left_index << 3) | right_index`. Pairs are ordered lexicographically by `(left_index,right_index)` and never have equal indices. The maximum is 56 bytes.
- Invalid input returns `-1`. A valid input with a null output buffer or insufficient capacity returns `-2` without writes, including an empty result with a null buffer.
- The ABI symbol is `palindrome_pairs`; workspace is 4096 bytes.

The primary uses palindromic prefix/suffix split checks and a reversed-word multimap. Each successful split performs a lookup for the reversed unmatched segment; a fixed pair bitmap removes duplicates before output ordering. The independent oracle tests each ordered pair directly by comparing the two ends of the virtual concatenation. With the fixed 17-slot table, the primary takes O(N L² + N²L) time in the duplicate-heavy worst case; direct pair checking takes O(N²L), where `N<=8` and `L<=8`.

## Distinctness and source

[`eertree`](../../e/eertree/README.md), [`manacher`](../../m/manacher/README.md), and [`count_different_palindromic_subsequences`](../../c/count_different_palindromic_subsequences/README.md) analyze one string's palindromic substrings or subsequences. [`word_boggle`](../../w/word_boggle/README.md) searches dictionary words along board paths. This package instead finds pairwise concatenations across a word list. The discovery source was LeetCode's public [Palindrome Pairs title page](https://leetcode.com/problems/palindrome-pairs/); the page was used as a title index only. No statement, constraints, examples, tests, submissions, or site code were used. See [`RIGHTS.md`](RIGHTS.md).

## Workload and oracles

- Workload: [`workload.json`](workload.json)
- Primary split-and-lookup oracle: [`primary_oracle.py`](primary_oracle.py)
- Independent direct-concatenation oracle: [`independent_oracle.py`](independent_oracle.py)
- Static package inventory checker: [`check_inventory.py`](check_inventory.py)

## Ports

The ten implementations are in `c/`, `c3/`, `cpp/`, `elisa/`, `mojo/`, `nim/`, `odin/`, `rust/`, `v/`, and `zig/` under their matching source directories.
