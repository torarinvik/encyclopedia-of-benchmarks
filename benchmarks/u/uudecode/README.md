# BitBench `uudecode`

This package ports the decoder in [`BitBench/uudecode/uudecode.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/uudecode/uudecode.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The input array contains one encoded file byte per signed 64-bit value. The bounded profile accepts at most 4,096 values and returns the decoded file bytes.

## Input format and bounds

- The header is exactly `begin 755 uustart.file \n`. The filename is fixed because the upstream decoder uses its length to locate the data; the mode and filename are not part of the decoded output.
- Each data line begins with an ASCII byte equal to 32 plus the number of decoded bytes on that line. Counts range from 1 through 45. The encoded body has four six-bit symbols per three decoded bytes, with symbols in ASCII range 32 through 95, and ends with one line feed.
- The final line is exactly ` \nend`. There is no final line feed after `end`. A partial final group produces only the byte count stated by its line marker; unused decoded bytes are ignored, as in the C source.
- A complete stream must follow the fixed header, complete data lines, and exact terminator. Inputs outside this bounded profile return `-1`. A null output pointer or output capacity smaller than the decoded result returns `-2` without writing bytes.
- The 4,096-byte input bound permits at most 2,949 decoded bytes: 65 full lines plus one 24-byte line fit with the header and terminator. The output workspace is 2,949 bytes.

The upstream launcher passes `input-file`. The pinned file is 747,647 bytes and its reference output is `542623\n`. The source decodes it 100 times, overwrites the same output buffer, and prints the final decoded size. The suite returns one decoded file per ABI call and keeps the 100-call repetition in `repetitions_per_sample`. The largest source-backed case uses the first 65 complete data lines, then the zero-length line and `end` marker.

[`workload.json`](workload.json) includes empty and short groups, 45-byte line boundaries, the bounded pinned fixture, maximum output, malformed streams, invalid byte values, and capacity cases. [`benchmarks/uudecode_oracle.py`](../../uudecode_oracle.py) supplies the runner oracle; [`benchmarks/uudecode_verifier_oracle.py`](../../uudecode_verifier_oracle.py) is an independent verification model.

Nine independent ports are provided: [C](../../../c/u/uudecode.c), [C3](../../../c3/u/uudecode.c3), [C++](../../../cpp/u/uudecode.cpp), [Elisa](../../../elisa/u/uudecode.elisa), [Nim](../../../nim/u/uudecode.nim), [Odin](../../../odin/u/uudecode.odin), [Rust](../../../rust/u/uudecode.rs), [V](../../../v/u/uudecode.v), and [Zig](../../../zig/u/uudecode.zig). The upstream GNU GPL and Berkeley BSD notices are retained in [`LICENSE-GPL-2.0-or-later.txt`](LICENSE-GPL-2.0-or-later.txt) and [`LICENSE-BSD-4-Clause.txt`](LICENSE-BSD-4-Clause.txt).
