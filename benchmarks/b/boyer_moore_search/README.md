# Boyer–Moore Search

The pinned C implementation prints every match using a bad-character table; Python and Rust return every match position and also use the bad-character rule. Rust indexes Unicode characters while the C implementation uses a fixed 256-byte table. The benchmark standardizes on the first byte match for bounded ASCII input and uses the bad-character heuristic.

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]` in the signed 64-bit array ABI.
- Text and pattern are each at most 4,096 bytes; every byte is ASCII, from 0 through 127.
- Return the first matching byte index, `0` for an empty pattern, and `-1` for no match or malformed input.
- The implementation uses a 128-entry last-occurrence table and compares pattern bytes from right to left.

## Workload and verification

[`workload.json`](workload.json) covers empty sequences, overlapping matches, bad-character skips, embedded NUL, ASCII boundary bytes, and long inputs. [`benchmarks/verify_boyer_moore_search.py`](../../verify_boyer_moore_search.py) checked 4,505 oracle arrays per language, including every pair of binary byte strings through length five, malformed inputs, deterministic random sequences, and long near-matches. All nine ports passed and each recorded all 13 workload cases.

## Upstream sources

- [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/searching/pattern_search/boyer_moore_search.c)
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/boyer_moore_search.py)
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/boyer_moore_search.rs)
