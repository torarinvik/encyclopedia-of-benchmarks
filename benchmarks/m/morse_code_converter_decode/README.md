# morse_code_converter_decode

This package implements the pinned Java `MorseCodeConverter.morseToText` direction as its own benchmark, measured separately from the opposite conversion direction.

## Contract

- Input is a signed i64 array of at most 512 ASCII code units in `0..127`. Empty input is valid.
- The decoder splits words only on the exact ` | ` separator, splits codes on one ASCII space, maps A–Z Morse codes to uppercase letters, and emits `?` for unknown or empty codes.
- The adapter preserves Java `String.split` behavior: leading and internal empty fields remain, trailing empty fields are dropped. The decoder maps an empty string to `?`.
- Invalid i64 values or code units outside ASCII return `-1`. Output is the resulting ASCII string as bytes; success returns its byte length. Insufficient capacity or a null output buffer returns `-2`.

The independent oracle is [`benchmarks/morse_code_converter_decode_oracle.py`](../../morse_code_converter_decode_oracle.py). The workload includes source examples, empty/unknown tokens, split boundaries, invalid inputs, capacity cases, and maximum input length.

Pinned source: [TheAlgorithms/Java `MorseCodeConverter.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/conversions/MorseCodeConverter.java).

## Build and record

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm morse_code_converter_decode --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_bytes_output.py --algorithm morse_code_converter_decode

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/morse_code_converter_decode.c](../../../c/m/morse_code_converter_decode.c) |
| C3 | [c3/m/morse_code_converter_decode.c3](../../../c3/m/morse_code_converter_decode.c3) |
| C++ | [cpp/m/morse_code_converter_decode.cpp](../../../cpp/m/morse_code_converter_decode.cpp) |
| Elisa | [elisa/m/morse_code_converter_decode.elisa](../../../elisa/m/morse_code_converter_decode.elisa) |
| Nim | [nim/m/morse_code_converter_decode.nim](../../../nim/m/morse_code_converter_decode.nim) |
| Odin | [odin/m/morse_code_converter_decode.odin](../../../odin/m/morse_code_converter_decode.odin) |
| Rust | [rust/m/morse_code_converter_decode.rs](../../../rust/m/morse_code_converter_decode.rs) |
| V | [v/morse_code_converter_decode.v](../../../v/morse_code_converter_decode.v) |
| Zig | [zig/m/morse_code_converter_decode.zig](../../../zig/m/morse_code_converter_decode.zig) |
