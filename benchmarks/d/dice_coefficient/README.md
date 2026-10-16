# Dice coefficient

This benchmark follows the pinned JavaScript string Dice coefficient. It compares adjacent two-character substrings (bigrams) from two strings and returns a binary64 score.

The source first returns `1` when the strings are equal, including when both are empty. If they differ and either has fewer than two characters, it returns `0`. Otherwise it records the bigrams present in the first string and scans each bigram occurrence in the second string. Every second-string occurrence counts when its bigram is present in the first string; the source does not consume the first string's frequency counts. It then computes `floor(score * 100) / 100`. This source behavior can produce a score above `1` when the second string repeats a matching bigram.

## Contract

- Pack signed 64-bit integers as `[lenA, lenB, A_codes..., B_codes...]`, with exactly `2 + lenA + lenB` values. Each length is in `0..=128`.
- Each code is a printable ASCII value in `32..=126`. Strings are case-sensitive.
- Return the source score as binary64. For non-equal strings shorter than two characters, the result is zero; equal strings, including empty strings, return one.
- Malformed packing or out-of-domain values return `-1e300`.

Printable ASCII avoids JavaScript UTF-16 surrogate and code-unit edge cases while keeping each source bigram represented exactly by a pair of bytes. The score uses the source's operation order and downward two-decimal truncation. The bounded domain is distinct from Jaccard similarity and distance, which compare sets rather than this source's bigram-presence scan.

## Source

- [TheAlgorithms/JavaScript `DiceCoefficient.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/String/DiceCoefficient.js), commit `5c39e87a9a31f279c60f830ad74a845e4788a517`.

See [`workload.json`](workload.json) for equality and short-string branches, a conventional overlap, the repeated-bigram behavior, and invalid packing/domain cases.

Verify all language ports against the bounded oracle and workload with `python3 benchmarks/verify_i64_array_float64.py --algorithm dice_coefficient`.
