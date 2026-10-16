# Detecting English Programmatically

The pinned Python implementation filters a message to ASCII letters plus space, tab, and newline, splits on whitespace, counts case-insensitive dictionary hits, and combines that word ratio with the retained-character ratio. The pinned module loads an uppercase word list from `dictionary.txt`; the benchmark supplies that dictionary explicitly so every port receives the same data.

## Contract

Input is a signed-i64 array encoded as `[dictionary_count, (word_length, uppercase_ASCII_word_bytes)*, message_length, message_ASCII_bytes..., word_percentage, letter_percentage]`. The dictionary contains 0–8 unique uppercase words of length 1–12 in strictly increasing bytewise order. The message contains 1–64 ASCII bytes; only A–Z, a–z, space, tab, and newline are retained by the tokenizer. Thresholds are integers from 0–100 and default to 20 and 85. Return 1 when the number of dictionary hits divided by token count meets the word threshold and retained message bytes divided by message byte count meets the letter threshold; otherwise return 0. Malformed encodings return -1. Empty messages and messages with no resulting tokens are invalid, matching the pinned source's division-by-zero path.

The benchmark bounds dictionary and message sizes to keep the source's dictionary lookup and parsing behavior deterministic across languages. It preserves the source's ASCII filtering and comparison semantics, with the dictionary passed as input rather than loaded from a process-local file.

## Workload and verification

`workload.json` covers matching and nonmatching tokens, punctuation filtering, threshold boundaries, and malformed inputs. `benchmarks/verify_detecting_english_programmatically.py` checks all nine ports against an independent oracle.

| Language | Source |
|---|---|
| C | [`c/d/detecting_english_programmatically.c`](../../../c/d/detecting_english_programmatically.c) |
| C3 | [`c3/d/detecting_english_programmatically.c3`](../../../c3/d/detecting_english_programmatically.c3) |
| C++ | [`cpp/d/detecting_english_programmatically.cpp`](../../../cpp/d/detecting_english_programmatically.cpp) |
| Elisa | [`elisa/d/detecting_english_programmatically.elisa`](../../../elisa/d/detecting_english_programmatically.elisa) |
| Nim | [`nim/d/detecting_english_programmatically.nim`](../../../nim/d/detecting_english_programmatically.nim) |
| Odin | [`odin/d/detecting_english_programmatically.odin`](../../../odin/d/detecting_english_programmatically.odin) |
| Rust | [`rust/d/detecting_english_programmatically.rs`](../../../rust/d/detecting_english_programmatically.rs) |
| V | [`v/d/detecting_english_programmatically.v`](../../../v/d/detecting_english_programmatically.v) |
| Zig | [`zig/d/detecting_english_programmatically.zig`](../../../zig/d/detecting_english_programmatically.zig) |

## Upstream source

- [TheAlgorithms/Python `detecting_english_programmatically.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/detecting_english_programmatically.py)
