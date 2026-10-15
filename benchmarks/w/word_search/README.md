# Word Search

Return `1` when the word can be formed from orthogonally adjacent board cells without using any cell more than once, and `0` when no such path exists. The benchmark packs a rectangular character board and word into one signed 64-bit array: `[rows, columns, row-major board character codes, word length, word character codes]`. Character codes are ASCII letters, so uppercase and lowercase remain distinct.

## Contract

- The board has 1 to 6 rows and 1 to 6 columns. Every row has the same number of columns.
- The word has 1 to 15 letters. Board and word contain only `A`-`Z` or `a`-`z` codes.
- Each cell can appear at most once in a matching path. Neighbors share an edge; diagonals do not count.
- Invalid packed inputs return `-1`. Valid answers are `0` or `1`.

## Algorithm and verification

The pinned C source recursively explores up, down, left, and right neighbors. It marks cells as visited before descending and restores the mark when backtracking. These ports preserve that DFS and backtracking behavior with a compact row-major visited array. The verifier compares against an independent Python search across exhaustive small boards and words, seeded random boards, official examples, case-sensitive inputs, and malformed packed arrays.

The pinned source contains a point-key calculation that does not match the compact board indexing. This benchmark uses the intended row-major cell index `row * columns + column` while preserving the traversal and visited-cell semantics.

The source is [TheAlgorithms C LeetCode `79.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/79.c); the problem statement is [LeetCode 79: Word Search](https://leetcode.com/problems/word-search/).

Build with the `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`. Verify all ports with `python3 benchmarks/verify_word_search.py`.
