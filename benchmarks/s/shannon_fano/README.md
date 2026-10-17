# Shannon–Fano prefix-code construction

This benchmark covers the pinned Java `ShannonFano.generateCodes` method. It counts 7-bit ASCII characters and recursively assigns Shannon–Fano prefix codes by splitting the frequency-sorted symbols into the most balanced contiguous groups.

## Contract

The ABI is `i64_array_bytes_output`. A non-null input is `[text_length, ASCII codes...]`, with text length 0 through 64 and codes in `0..127`. The packed length must equal `1 + text_length`. A null input pointer with length zero represents Java `null`; like an empty string, it returns an empty map. A null pointer with positive length is invalid.

The pinned source sorts symbols by descending frequency. Since Java's stable sort preserves the unspecified `HashMap` iteration order for equal frequencies, inputs with tied frequencies for distinct symbols are invalid. This leaves an unambiguous symbol order. The split scan updates its choice only for a strictly smaller difference, so equal-difference splits use the earliest split index. The left partition gets bit `0`, the right gets bit `1`, and a single-symbol input receives code `0`.

Serialize the result map in ascending symbol-byte order as one symbol-count byte, followed by each entry's symbol byte, code-length byte, and ASCII `0`/`1` code bytes. Sorting the returned map for serialization makes its unspecified iteration order irrelevant. At most ten symbols can have distinct positive frequencies in a 64-character input; the maximum code length is nine and the serialized output is bounded by 111 bytes. Malformed framing, unsupported lengths, out-of-range symbols, or tied frequencies return `-1` before output checks. A null output or insufficient capacity returns `-2` without writes.

## Pinned source

- `ShannonFano.generateCodes`, `buildCodeTree`, and `findSplitIndex`: [TheAlgorithms/Java at `e43ec3897e48f23843972d02cd05a5bb1b6864a2`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/ShannonFano.java)

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`shannon_fano_oracle.py`](../../shannon_fano_oracle.py)
