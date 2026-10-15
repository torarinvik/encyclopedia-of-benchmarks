# Isogram

The pinned C source checks for repeated bytes exactly, while Java exposes both alphabetic-only and all-character variants. Rust ignores spaces, folds ASCII case, and rejects other nonletter characters. The shared contract uses the common word-and-phrase interpretation with explicit ASCII rules.

## Contract

- Input is an array of 0–4,096 signed 64-bit values representing ASCII bytes.
- Accept only `A`–`Z`, `a`–`z`, and ASCII space.
- Compare letters without case sensitivity and ignore spaces.
- Return `1` if no letter repeats, `0` if a letter repeats, and `-1` for invalid input.
- The implementations use a 26-entry local table and need no architecture-specific operations.

## Workload and verification

[`workload.json`](workload.json) covers empty input, pangrams, mixed case, spaces, repeated letters, invalid bytes, and maximum-length inputs. [`benchmarks/verify_isogram.py`](../../verify_isogram.py) checked 4,440 oracle arrays per language, including exhaustive strings over a small case-and-space alphabet, invalid bytes, deterministic random sequences, and maximum-length boundaries. All nine ports passed and each recorded the 14 workload cases.

## Upstream sources

- [C](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/exercism/isogram/isogram.c)
- [C header](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/exercism/isogram/isogram.h)
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/Isogram.java)
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/isogram.rs)
