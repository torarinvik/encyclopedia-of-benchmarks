# Detecting English Programmatically

The pinned Python implementation filters a message to ASCII letters plus space, tab, and newline, splits on whitespace, counts case-insensitive dictionary hits, and combines that word ratio with the retained-character ratio. The pinned module loads an uppercase word list from `dictionary.txt`; the benchmark supplies that dictionary explicitly so every port receives the same data.

## Contract

Input is a signed-i64 array encoded as `[dictionary_count, (word_length, uppercase_ASCII_word_bytes)*, message_length, message_ASCII_bytes..., word_percentage, letter_percentage]`. The dictionary contains 0–8 unique uppercase words of length 1–12 in strictly increasing bytewise order. The message contains 1–64 ASCII bytes; only A–Z, a–z, space, tab, and newline are retained by the tokenizer. Thresholds are integers from 0–100 and default to 20 and 85. Return 1 when the number of dictionary hits divided by token count meets the word threshold and retained message bytes divided by message byte count meets the letter threshold; otherwise return 0. Malformed encodings return -1. Empty messages are invalid, since the pinned source divides by zero for them; messages with no tokens return 0.

The benchmark bounds dictionary and message sizes to keep the source's dictionary lookup and parsing behavior deterministic across languages. It preserves the source's ASCII filtering and comparison semantics, with the dictionary passed as input rather than loaded from a process-local file.

## Workload and verification

`workload.json` covers matching and nonmatching tokens, punctuation filtering, threshold boundaries, and malformed inputs. `benchmarks/verify_detecting_english_programmatically.py` checks all nine ports against an independent oracle.

## Upstream source

- [TheAlgorithms/Python `detecting_english_programmatically.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/detecting_english_programmatically.py)
