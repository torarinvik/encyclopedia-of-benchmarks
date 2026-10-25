# Embench-IoT QRduino encoder

This is a clean-room, bounded implementation of the QR-code encoder workload
from Embench-IoT's qrduino benchmark. It encodes byte-mode data as a version
2, error-correction-level L symbol: it builds the padded data codewords,
computes Reed–Solomon parity over GF(256), places codeword bits into the
function-module frame, and evaluates the eight mask candidates with format
information.

## Contract

The i64_array_bytes_output input is [message_length, byte_0, ...].
message_length is 1–21 and must equal the number of following values. Each
byte is nonzero ASCII (1–127); embedded NUL and non-ASCII bytes are rejected.
This keeps the source benchmark's C-string length semantics explicit and
ensures the payload fits the fixed version 2-L profile.

The output is the first 22 bytes of the row-packed unmasked QR frame after
data and parity placement. The original benchmark verifies this prefix of its
working buffer before applying masks and format bits. Success returns 22;
malformed input returns -1; a null output pointer or capacity below 22 returns
-2 without writing output. The ABI accepts up to 23 input values so it can
reject a declared 22-byte message cleanly.

workload.json includes the source benchmark's payload and verified output
prefix, malformed framing and payload values, null input and output, and
insufficient capacity. The independent oracle is
[qrduino_oracle.py](../../qrduino_oracle.py).

## Provenance and rights

The source is
[src/qrduino/qrencode.c](https://github.com/embench/embench-iot/blob/de24bdf561f4eaad7f37685641fa301f2b8b4bc3/src/qrduino/qrencode.c)
and
[src/qrduino/qrframe.c](https://github.com/embench/embench-iot/blob/de24bdf561f4eaad7f37685641fa301f2b8b4bc3/src/qrduino/qrframe.c)
at Embench-IoT commit
[de24bdf561f4eaad7f37685641fa301f2b8b4bc3](https://github.com/embench/embench-iot/commit/de24bdf561f4eaad7f37685641fa301f2b8b4bc3).
Those files declare GPL-3.0-or-later and attribute the benchmark to Embecosm
Limited and the University of Bristol, with contributions from James Pallister
and Jeremy Bennett; the original QRduino project is
[tz1/qrduino](https://github.com/tz1/qrduino). This package is licensed
under GPL-3.0-or-later; the complete license text is in [LICENSE.txt](LICENSE.txt).
The implementations were written independently from the QR encoding
specification and benchmark contract; no upstream implementation code or
tables were copied or translated.

| Language | Port |
| --- | --- |
| C | [qrduino.c](../../../c/q/qrduino.c) |
| C3 | [qrduino.c3](../../../c3/q/qrduino.c3) |
| C++ | [qrduino.cpp](../../../cpp/q/qrduino.cpp) |
| Elisa | [qrduino.elisa](../../../elisa/q/qrduino.elisa) |
| Nim | [qrduino.nim](../../../nim/q/qrduino.nim) |
| Odin | [qrduino.odin](../../../odin/q/qrduino.odin) |
| Rust | [qrduino.rs](../../../rust/q/qrduino.rs) |
| V | [qrduino.v](../../../v/q/qrduino.v) |
| Zig | [qrduino.zig](../../../zig/q/qrduino.zig) |
