# Java LZ77 compression

This contract follows the pinned Java `LZ77.compress(String)` overload with its defaults: a 4096-character search window and a 16-character lookahead buffer. It is kept separate from the Python and Rust variants because their default window geometry, tie-breaking, and end token differ.

## Contract

Input is `[n, character_code_0, ..., character_code_(n-1)]`, with `n` from 0 through 64 and each character code in printable ASCII `[32,126]`. The input length is exactly `1+n`; one additional word is parseable for a malformed-frame case. The printable domain excludes the source's NUL end-of-stream marker.

At each position, search prior characters from oldest to newest, considering at most the previous 4096 characters. Compare matches through the lookahead end, at most 16 characters ahead. Overlapping matches wrap through the candidate period as the Java source does. Replace the best match only when a strictly longer match is found, so the first (farthest) candidate wins a tie. Emit `(offset, length, nextChar)`, where `nextChar` is the following character or 0 when the match reaches end of input. Advance by `length` for the 0 end marker and by `length+1` otherwise. At the maximum 64-character input, the entire prior text fits in the default search window.

Output is a sequence of little-endian signed-i64 triples `(offset, length, nextChar)` with no count prefix. A successful call returns the number of bytes written; the maximum is 1536 bytes. Empty input returns zero bytes. The benchmark covers `compress` only; `decompress` is outside the operation. Malformed framing or unsupported characters return `-1` before output checks. A null output pointer or capacity below the encoded result size returns `-2`; errors write no bytes.

The independent oracle is [`../../lz77_java_oracle.py`](../../lz77_java_oracle.py). The workload includes overlap, an end-of-stream token, first-longest tie selection, the 16-character lookahead boundary, maximum output, malformed input, and output-capacity cases.

## Language ports

| Language | Source |
| --- | --- |
| C | [lz77_java.c](../../../c/l/lz77_java.c) |
| C3 | [lz77_java.c3](../../../c3/l/lz77_java.c3) |
| C++ | [lz77_java.cpp](../../../cpp/l/lz77_java.cpp) |
| Elisa | [lz77_java.elisa](../../../elisa/l/lz77_java.elisa) |
| Nim | [lz77_java.nim](../../../nim/l/lz77_java.nim) |
| Odin | [lz77_java.odin](../../../odin/l/lz77_java.odin) |
| Rust | [lz77_java.rs](../../../rust/l/lz77_java.rs) |
| V | [lz77_java.v](../../../v/l/lz77_java.v) |
| Zig | [lz77_java.zig](../../../zig/l/lz77_java.zig) |

## Pinned source

- TheAlgorithms/Java [`LZ77.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/compression/LZ77.java), specifically the default `compress(String)` overload.
