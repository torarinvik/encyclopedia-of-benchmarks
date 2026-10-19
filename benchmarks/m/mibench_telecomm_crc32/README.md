# MiBench telecomm-CRC32

This package ports the CRC-32 kernel selected by the pinned MiBench launcher.
The source uses Gary S. Brown's 256-entry table and `UPDC32` update. The ports
use the same reflected IEEE CRC-32 polynomial (`0xEDB88320`), initial state
`0xFFFFFFFF`, per-byte table update, and final XOR.

## Source and bounded contract

The pinned [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-CRC32/info.sh)
builds only `crc_32.c` and runs it on `large.pcm`. Its `crc32file` routine
processes the file byte by byte and prints the checksum, byte count, and
basename. The same source exposes `crc32buf`, which computes the checksum of a
caller-provided byte buffer. This suite measures that kernel directly and
returns the unsigned CRC-32 value in signed 64-bit integer storage.

The bounded suite profile accepts 0 through 100,001 bytes, represented as an
array of integer values from 0 through 255. It matches the source's byte
interpretation, including values above 127. Invalid lengths, null nonempty
arrays, or values outside the byte range return -1. Input is not modified.
The empty input checksum is 0. The output is the integer form of the CRC; the
source's `printf` formatting and file-name reporting are outside this
kernel-level contract.

[`workload.json`](workload.json) records the launcher, bounded byte-array
profile, and deterministic fixtures. The independent
[`mibench_telecomm_crc32_oracle.py`](../../mibench_telecomm_crc32_oracle.py)
uses a bit-at-a-time recurrence rather than the ports' lookup table.

The upstream [`LICENSE`](LICENSE.txt) says this code is free with no
restrictions. [`NOTICE.txt`](NOTICE.txt) preserves the source attribution.

| Language | Port |
|---|---|
| C | [`c/m/mibench_telecomm_crc32.c`](../../../c/m/mibench_telecomm_crc32.c) |
| C3 | [`c3/m/mibench_telecomm_crc32.c3`](../../../c3/m/mibench_telecomm_crc32.c3) |
| C++ | [`cpp/m/mibench_telecomm_crc32.cpp`](../../../cpp/m/mibench_telecomm_crc32.cpp) |
| Elisa | [`elisa/m/mibench_telecomm_crc32.elisa`](../../../elisa/m/mibench_telecomm_crc32.elisa) |
| Nim | [`nim/m/mibench_telecomm_crc32.nim`](../../../nim/m/mibench_telecomm_crc32.nim) |
| Odin | [`odin/m/mibench_telecomm_crc32.odin`](../../../odin/m/mibench_telecomm_crc32.odin) |
| Rust | [`rust/m/mibench_telecomm_crc32.rs`](../../../rust/m/mibench_telecomm_crc32.rs) |
| V | [`v/m/mibench_telecomm_crc32.v`](../../../v/m/mibench_telecomm_crc32.v) |
| Zig | [`zig/m/mibench_telecomm_crc32.zig`](../../../zig/m/mibench_telecomm_crc32.zig) |

## Pinned files

- [`crc_32.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-CRC32/crc_32.c)
- [`crc.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-CRC32/crc.h)
- [`LICENSE`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-CRC32/LICENSE)
