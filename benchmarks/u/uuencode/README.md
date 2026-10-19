# BitBench uuencode

This package ports the bounded byte encoder from [`BitBench/uuencode/uuencode.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/BitBench/uuencode/uuencode.c) at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`. The input is an array of raw byte values from 0 through 255, capped at 4,096 bytes. The function returns the complete ASCII encoding as output bytes.

## Output format

- The fixed header is exactly `begin 640 uuencode.c \n`; the space before the line feed is part of the source output.
- Data is split into lines of at most 45 input bytes. Each line begins with the encoded byte count, followed by four six-bit symbols per three input bytes. A symbol is `32 + (value & 63)`, so the alphabet occupies ASCII space through underscore.
- A one-byte tail is followed by two `=` characters; a two-byte tail is followed by one `=`. Every data line ends with one line feed.
- The stream always ends with the zero-length line and `end`: exactly ` \nend`. The final `d` has no following newline. Empty input therefore produces the header followed immediately by this terminator.
- Invalid pointers, lengths, or byte values return `-1`. A null output pointer or short output capacity returns `-2` without writing bytes. Maximum input is 4,096 bytes; maximum output is 5,675 bytes.

The upstream program encodes the same input 1,000 times inside its timing loop, replacing the previous output each time, then prints the final stream length. Its pinned full-input reference is `1030121\n`. The suite preserves that repeat count as `repetitions_per_sample: 1000`; one ABI call returns one encoded stream. The largest fixture is the first 4,096 bytes of the pinned upstream `input` file, whose complete source input is 747,648 bytes.

## Workload and ports

[`workload.json`](workload.json) includes empty and short tails, exact 45-byte line boundaries, all byte values, invalid and capacity cases, and the pinned source input prefix. [`benchmarks/uuencode_oracle.py`](../../uuencode_oracle.py) supplies the Python oracle.

Nine independent ports are provided: [C](../../../c/u/uuencode.c), [C3](../../../c3/u/uuencode.c3), [C++](../../../cpp/u/uuencode.cpp), [Elisa](../../../elisa/u/uuencode.elisa), [Nim](../../../nim/u/uuencode.nim), [Odin](../../../odin/u/uuencode.odin), [Rust](../../../rust/u/uuencode.rs), [V](../../../v/u/uuencode.v), and [Zig](../../../zig/u/uuencode.zig). The two upstream notices are retained in [`LICENSE-GPL-2.0-or-later.txt`](LICENSE-GPL-2.0-or-later.txt) and [`LICENSE-BSD-4-Clause.txt`](LICENSE-BSD-4-Clause.txt).
