# Convert number to words

This package ports the pinned [TheAlgorithms/Python converter](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/convert_number_to_words.py), including its short-scale, long-scale, and Indian numbering systems. It recursively names nonzero groups, uses hyphenated English words below one hundred, and prefixes negative values with `negative`.

The `i64_array_bytes_output` ABI accepts `[number, system]`, where system code `0` selects short scale, `1` long scale, and `2` Indian scale. To fit the signed 64-bit input ABI, the supported magnitude is at most `999,999,999,999,999,999` for short scale and `9,000,000,000,000,000,000` for long and Indian scale. Output is the exact lowercase ASCII phrase from the source. Invalid values return `-1`; insufficient output capacity returns `-2`; success returns the number of output bytes.

## Workload

[`workload.json`](workload.json) includes the source examples across all three systems, negative and hyphenated values, bounds, and malformed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/convert_number_to_words.c`](../../../c/c/convert_number_to_words.c) |
| C3 | [`c3/c/convert_number_to_words.c3`](../../../c3/c/convert_number_to_words.c3) |
| C++ | [`cpp/c/convert_number_to_words.cpp`](../../../cpp/c/convert_number_to_words.cpp) |
| Elisa | [`elisa/c/convert_number_to_words.elisa`](../../../elisa/c/convert_number_to_words.elisa) |
| Nim | [`nim/c/convert_number_to_words.nim`](../../../nim/c/convert_number_to_words.nim) |
| Odin | [`odin/c/convert_number_to_words.odin`](../../../odin/c/convert_number_to_words.odin) |
| Rust | [`rust/c/convert_number_to_words.rs`](../../../rust/c/convert_number_to_words.rs) |
| V | [`v/c/convert_number_to_words.v`](../../../v/c/convert_number_to_words.v) |
| Zig | [`zig/c/convert_number_to_words.zig`](../../../zig/c/convert_number_to_words.zig) |
