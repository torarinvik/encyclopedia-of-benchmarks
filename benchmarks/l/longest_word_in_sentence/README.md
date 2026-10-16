# Longest Word in a Sentence

This benchmark returns the first longest word from an ASCII sentence, matching the pinned Python implementation's `split()` and `max(..., key=len)` behavior. ASCII spaces and horizontal or vertical ASCII whitespace separate words; punctuation is part of a word. Empty or whitespace-only input returns an empty byte string. When words tie for maximum length, the first one is returned.

## Contract

- Input is a signed 64-bit integer array `[text_length, byte...]` with `0 <= text_length <= 1024` and exactly `1 + text_length` elements.
- Text bytes may be printable ASCII (`0x21` through `0x7e`) or ASCII whitespace (`0x09` through `0x0d`, and `0x20`). Other bytes and malformed arrays return `-1`.
- The result is the selected word as raw ASCII bytes, with no terminator. The return value is its byte length. An empty result has length zero.
- Insufficient output capacity returns `-2` without writing.
- The scan takes O(n) time and O(1) auxiliary space.

The ASCII domain keeps byte length equal to character length across every target runtime. The upstream Python function also accepts Unicode strings; those inputs are outside this portable benchmark contract.

## Source and verification

The pinned source is [TheAlgorithms/Python `strings/longest_word_in_sentence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/longest_word_in_sentence.py). It splits on whitespace and selects the first word among equal-length maxima. All nine target-language implementations preserve those semantics in the documented ASCII domain.

`workload.json` covers empty and whitespace-only input, tabs and newlines, punctuation, ties, malformed bytes, and the maximum text length. The verifier checks generated short inputs and deterministic randomized inputs against an independent word-selection oracle.
