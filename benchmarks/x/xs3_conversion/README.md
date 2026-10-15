# XS-3 Conversion

This benchmark covers both conversion directions from the pinned Java `Xs3Conversion` class. The input selects one operation and supplies its value: direction `0` decodes a packed XS-3 word into a decimal integer; direction `1` encodes a nonnegative decimal integer as packed XS-3 nibbles.

## Contract

- The read-only signed 64-bit input is exactly `[direction, value]`.
- Decode (`direction = 0`) accepts `value` from 0 through `2,147,483,647`. Every hexadecimal nibble present in the integer must be 3 through 12. The source reads the low nibble first, subtracts 3, and accumulates decimal place values.
- Encode (`direction = 1`) accepts decimal values from 0 through 9,999,999. It adds 3 to each decimal digit and places those values in successive low-to-high nibbles, matching the source's operation order.
- Zero follows the source loops: encoding zero returns packed value 0, and decoding zero returns 0. The integer API does not retain leading-zero digits.
- Wrong packed length, an unknown direction, or an out-of-domain value returns `-1`.
- The encoding bound ensures the packed value remains a nonnegative Java `int`; the decoding bound keeps all source-style decimal accumulation in range.

The paired packed-word operations differ from the Python `excess_3_code` string representation. They also differ from `binary_to_excess3`, which parses an entire binary numeral and adds 3 once rather than encoding each decimal digit.

## Workload

[`workload.json`](workload.json) covers both directions, the source's zero behavior, nibble/digit boundaries, the maximum encoding value, and malformed or out-of-domain inputs.

The shared scalar-array runner validates both directions with the source's least-significant-nibble-first arithmetic and its integer bounds.

## Reviewed source

- [Java `Xs3Conversion.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/Xs3Conversion.java) — `xs3ToBinary` and `binaryToXs3`.
- [Python `excess_3_code.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/excess_3_code.py) — related per-digit encoding with a textual result.
- [Python `binary_to_excess3.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/binary_to_excess3.py) — a distinct whole-binary-integer conversion.

## Implementations

The nine portable ports use the shared `i64_array_scalar` ABI. Their source files are in the `x` folder for each language.
