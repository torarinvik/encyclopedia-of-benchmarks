# Match word pattern

`match_word_pattern` checks whether a pattern can map bijectively to nonempty substrings of a text. Repeated pattern symbols must map to the same substring, and distinct symbols must map to different substrings. The pinned Python implementation tries candidate substrings from shortest to longest and backtracks when a mapping fails.

## Contract

Input uses the `i64_array_scalar` ABI and is packed as `[pattern_length, text_length, pattern_bytes..., text_bytes...]`. Pattern length is 0–8; text length is 0–32; every byte is ASCII 0–127, including NUL. The packed array must have exactly `2 + pattern_length + text_length` elements. Return 1 for a match, 0 for a valid non-match, and -1 for malformed input or a null input pointer. An empty pattern matches only an empty text. Each pattern symbol maps to a nonempty substring, so a nonempty pattern cannot match an empty text.

The recursive search follows the source's shortest-candidate-first order and enforces both the symbol-to-substring map and its inverse. The bounds cap recursion at eight pattern positions and the input at 42 signed 64-bit values.

[`workload.json`](workload.json) includes empty inputs, repeated symbols, inconsistent mappings, duplicate-substring rejection, source examples, ASCII NUL, maximum bounds, null input, and malformed framing/domain cases.

## Pinned source

- [Python `match_word_pattern.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/backtracking/match_word_pattern.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`, symbol `match_word_pattern`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/match_word_pattern.c`](../../../c/match_word_pattern.c) |
| C3 | [`c3/m/match_word_pattern.c3`](../../../c3/match_word_pattern.c3) |
| C++ | [`cpp/m/match_word_pattern.cpp`](../../../cpp/m/match_word_pattern.cpp) |
| Elisa | [`elisa/m/match_word_pattern.elisa`](../../../elisa/m/match_word_pattern.elisa) |
| Nim | [`nim/m/match_word_pattern.nim`](../../../nim/m/match_word_pattern.nim) |
| Odin | [`odin/m/match_word_pattern.odin`](../../../odin/m/match_word_pattern.odin) |
| Rust | [`rust/m/match_word_pattern.rs`](../../../rust/m/match_word_pattern.rs) |
| V | [`v/m/match_word_pattern.v`](../../../v/m/match_word_pattern.v) |
| Zig | [`zig/m/match_word_pattern.zig`](../../../zig/m/match_word_pattern.zig) |

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm match_word_pattern --language rust
python3 benchmarks/verify_i64_array_scalar.py --algorithms match_word_pattern
```
