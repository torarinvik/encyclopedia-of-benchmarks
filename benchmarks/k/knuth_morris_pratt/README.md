# Knuth–Morris–Pratt

The pinned C++, F#, Python, and Rust sources use Knuth–Morris–Pratt matching but expose different results: the C++ and Python functions return a first-match position, F# returns a Boolean, and Rust returns all match positions using Unicode character indices. The benchmark uses a portable byte-oriented contract, so each target returns the first match index for an ASCII byte sequence.

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]` in the signed 64-bit array ABI.
- Text and pattern are each at most 4,096 bytes. Every byte must be ASCII, from 0 through 127.
- Return the zero-based index of the first match, `0` for an empty pattern, and `-1` for no match or invalid packed input.
- The KMP prefix table and search are linear in the combined sequence length. Implementations use fixed local storage bounded by the input limit.

## Workload and verification

[`workload.json`](workload.json) includes empty inputs, repeated and overlapping matches, prefix fallback, byte boundaries, and a long near-match. [`benchmarks/verify_knuth_morris_pratt.py`](../../verify_knuth_morris_pratt.py) checked 4,504 oracle arrays per language, including every text/pattern pair over a binary alphabet through length five, malformed inputs, deterministic random inputs, and long-prefix cases. All nine portable implementations passed and each recorded all 12 workload cases.

## Upstream sources

The C LeetCode [`28.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/leetcode/src/28.c) contains a KMP implementation after its direct-scan `strStr` definition.

- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/strings/knuth_morris_pratt.cpp)
- [C++ additional repository](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/strings/knuth_morris_pratt.cpp)
- [F#](https://github.com/TheAlgorithms/F-Sharp/blob/e5441e8bfd2cda87541634b75f39f0868447ae5f/Algorithms/Strings/KnuthMorrisPratt.fs)
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/knuth_morris_pratt.py)
- [Rust](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/knuth_morris_pratt.rs)
