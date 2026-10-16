# Knuth–Morris–Pratt Substring Existence

This package ports the Dart `stringCompare` function as a Boolean substring search. It is separate from [`knuth_morris_pratt`](../knuth_morris_pratt/README.md), which returns the first match index.

## Contract

- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]` in the signed 64-bit array ABI.
- Text and pattern lengths are each 0 through 4,096 bytes. Every byte must be ASCII, from 0 through 127, and the packed input length must match the two lengths.
- Return 1 if the pattern occurs in the text, or 0 otherwise. An empty pattern returns 0, following the Dart source. Malformed input returns -1.
- The KMP prefix table and search take `O(text_length + pattern_length)` time and `O(pattern_length)` auxiliary space.

The Dart source indexes strings by UTF-16 code units. This contract restricts inputs to ASCII, where each character occupies one UTF-16 code unit and one byte, so all nine ports compare the same sequence.

## Source

The pinned Dart file is named `knuth_morris_prat.dart` (the filename has a typo). Its `stringCompare` function builds a failure table, scans the text with fallback, and returns false immediately for an empty pattern.

- [TheAlgorithms Dart `knuth_morris_prat.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/strings/knuth_morris_prat.dart)

## Workload

[`workload.json`](workload.json) covers empty inputs, positive and negative matches, fallback after a partial match, embedded NUL and DEL bytes, maximum-size strings, and malformed packed inputs.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm knuth_morris_pratt_contains --language rust
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/k/knuth_morris_pratt_contains/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/knuth_morris_pratt_contains.c`](../../../c/k/knuth_morris_pratt_contains.c) |
| C3 | [`c3/k/knuth_morris_pratt_contains.c3`](../../../c3/k/knuth_morris_pratt_contains.c3) |
| C++ | [`cpp/k/knuth_morris_pratt_contains.cpp`](../../../cpp/k/knuth_morris_pratt_contains.cpp) |
| Elisa | [`elisa/k/knuth_morris_pratt_contains.elisa`](../../../elisa/k/knuth_morris_pratt_contains.elisa) |
| Nim | [`nim/k/knuth_morris_pratt_contains.nim`](../../../nim/k/knuth_morris_pratt_contains.nim) |
| Odin | [`odin/k/knuth_morris_pratt_contains.odin`](../../../odin/k/knuth_morris_pratt_contains.odin) |
| Rust | [`rust/k/knuth_morris_pratt_contains.rs`](../../../rust/k/knuth_morris_pratt_contains.rs) |
| V | [`v/k/knuth_morris_pratt_contains.v`](../../../v/k/knuth_morris_pratt_contains.v) |
| Zig | [`zig/k/knuth_morris_pratt_contains.zig`](../../../zig/k/knuth_morris_pratt_contains.zig) |
