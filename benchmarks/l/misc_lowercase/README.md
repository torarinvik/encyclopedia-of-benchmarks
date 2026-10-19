# LAC-DCC `lowercase`

This package isolates the pinned source's `lower_StringImpl` helper. It lowercases only ASCII uppercase letters in unsigned 16-bit code units using the source's ASCII mapping, preserves every other code unit, and reports whether all original input units were ASCII. The source driver builds a repeated test string and calls the helper for lengths 0 through 31; this package exposes that bounded helper operation directly, without the driver's ten-million-call timing loop or console messages.

## Contract

The `i64_array_bytes_output` symbol is `misc_lowercase(input, input_length, output, output_capacity)`. Input is `[character_count, code_unit_0, ...]`; the count is 0 through 31, the frame must contain exactly that many code units after its header, and each unit is 0 through 65,535. Output is one ASCII-status byte (`1` if every original code unit is at most `0x7f`, otherwise `0`), followed by the mapped code units as little-endian 16-bit values. Only values in `A` through `Z` change, by adding 32. Invalid input returns -1. A null or undersized output buffer returns -2 without writing. Maximum output is 63 bytes.

The output is a numeric encoding of the helper result, not the source driver's printed `iterations (N characters)` status lines. See [workload.json](workload.json) and the independent [oracle](../../misc_lowercase_oracle.py).

## Pinned source

- [lowercase.c at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/lowercase/lowercase.c)
- [info.sh at the pinned commit](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Misc/lowercase/info.sh)

## Implementations

| Language | Source |
| --- | --- |
| C | [c/l/lac_dcc_lowercase.c](../../../c/l/lac_dcc_lowercase.c) |
| C3 | [c3/l/lac_dcc_lowercase.c3](../../../c3/l/lac_dcc_lowercase.c3) |
| C++ | [cpp/l/lac_dcc_lowercase.cpp](../../../cpp/l/lac_dcc_lowercase.cpp) |
| Elisa | [elisa/l/lac_dcc_lowercase.elisa](../../../elisa/l/lac_dcc_lowercase.elisa) |
| Nim | [nim/l/lac_dcc_lowercase.nim](../../../nim/l/lac_dcc_lowercase.nim) |
| Odin | [odin/l/lac_dcc_lowercase.odin](../../../odin/l/lac_dcc_lowercase.odin) |
| Rust | [rust/l/lac_dcc_lowercase.rs](../../../rust/l/lac_dcc_lowercase.rs) |
| V | [v/l/lac_dcc_lowercase.v](../../../v/l/lac_dcc_lowercase.v) |
| Zig | [zig/l/lac_dcc_lowercase.zig](../../../zig/l/lac_dcc_lowercase.zig) |
