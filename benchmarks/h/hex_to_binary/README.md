# Hex to binary

Convert each hexadecimal character independently to its four-bit binary group. The fixed-width output preserves leading zeroes in every input digit.

## Contract

The `i64_array_bytes_output` input is a vector of ASCII byte values, from zero through 256 entries. Each value must encode one hexadecimal character (`0`-`9`, `A`-`F`, or `a`-`f`). A valid call returns the number of output bytes, exactly four per input character. Invalid input returns `-1`; a null output pointer or insufficient capacity returns `-2`.

The output is ASCII text containing only `0` and `1`, with no separator or prefix. Empty input returns an empty output. Unlike [`hexadecimal_to_binary`](../hexadecimal_to_binary/README.md), this algorithm preserves one four-bit group for every source digit, including leading zeroes.

## Workload

[`workload.json`](workload.json) covers numeric and alphabetic digits, both letter cases, leading zeroes, empty input, invalid characters, and short capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/hex_to_binary.c`](../../../c/h/hex_to_binary.c) |
| C3 | [`c3/h/hex_to_binary.c3`](../../../c3/h/hex_to_binary.c3) |
| C++ | [`cpp/h/hex_to_binary.cpp`](../../../cpp/h/hex_to_binary.cpp) |
| Elisa | [`elisa/h/hex_to_binary.elisa`](../../../elisa/h/hex_to_binary.elisa) |
| Nim | [`nim/h/hex_to_binary.nim`](../../../nim/h/hex_to_binary.nim) |
| Odin | [`odin/h/hex_to_binary.odin`](../../../odin/h/hex_to_binary.odin) |
| Rust | [`rust/h/hex_to_binary.rs`](../../../rust/h/hex_to_binary.rs) |
| V | [`v/h/hex_to_binary.v`](../../../v/h/hex_to_binary.v) |
| Zig | [`zig/h/hex_to_binary.zig`](../../../zig/h/hex_to_binary.zig) |

## Pinned source

- JavaScript [`HexToBinary.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/HexToBinary.js)
