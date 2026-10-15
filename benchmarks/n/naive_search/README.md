# Naive pattern search

Find every occurrence of a pattern in a text by comparing each candidate window from left to right. The result preserves ascending start positions, including overlapping matches.

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]`. Each sequence length is from 0 through 255, and the packed array must have exactly `2 + text_length + pattern_length` values.
- Text and pattern bytes must be non-NUL ASCII values 1 through 127. Empty text and pattern are valid.
- The function returns the number of matches and writes their zero-based positions in ascending order, one position byte per output byte. A text length of at most 255 ensures every position, including the final empty-pattern boundary, fits in one byte.
- An empty pattern matches at every text boundary, from 0 through `text_length`; a pattern longer than the text has no matches. Invalid packed input returns `-1`; insufficient output capacity returns `-2`.
- The direct comparison algorithm takes `O((n-m+1)m)` time when `m ≤ n` and `O(1)` auxiliary space apart from the returned positions.

## Relationship to Rabin–Karp

The existing `rabin_karp` benchmark uses a rolling hash and reports only whether the pattern occurs. This package preserves the C candidate's all-match output and direct window-comparison strategy, so overlapping matches remain observable.

## Reviewed source

- [C `naive_search.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/pattern_search/naive_search.c)

## Workload

[`workload.json`](workload.json) covers empty patterns, overlapping and repeated matches, no match, a pattern longer than the text, exact matches, ASCII boundaries, and malformed packed data. The nine ports use the shared `i64_array_bytes_output` ABI.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm naive_search --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/n/naive_search/rust/build.json
```
