# CRC32

CRC32 computes the IEEE CRC-32 checksum of an unsigned-byte sequence. The package shares the `i64_array_scalar` ABI used by byte-array algorithms such as Adler-32.

Input is an array of 0 to 100,001 integer byte values, each from 0 through 255. The checksum starts at `0xFFFFFFFF`; each byte is processed with the reflected polynomial `0xEDB88320`, and the final value is XORed with `0xFFFFFFFF`. The result is returned as an unsigned 32-bit value represented in signed 64-bit storage. Invalid lengths or byte values return `-1`. Input is not modified.

The Java source exposes both a `String` overload using the platform's default byte encoding and a byte-array overload. The benchmark uses the byte-array contract so input bytes are identical across languages. Its bit-at-a-time, forward-polynomial implementation followed by bit reversal is equivalent to the reflected CRC-32 recurrence used by the Python lookup-table implementation.

The pinned C `hash_crc32` source uses the same reflected IEEE CRC-32 recurrence, but accepts a NUL-terminated string rather than an explicit byte array. It aliases this benchmark only for empty or NUL-free ASCII input (bytes 1–127); embedded NUL bytes terminate its scan, and its API has no explicit length or invalid-input sentinel. The benchmark retains the broader 0–255 byte-array domain.

The pinned MiBench `crc32buf` kernel also computes this reflected IEEE CRC-32 value, using a 256-entry lookup table rather than the benchmark's bit-at-a-time recurrence. Its table is an implementation optimization of the same algorithm, so the MiBench source maps to this package rather than a second benchmark. The MiBench launcher adds file input and report formatting; its pinned source is [`crc_32.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/telecomm-CRC32/crc_32.c).

The cBench `telecom_CRC32` copy uses the same `crc_32.c` implementation and reflected IEEE table recurrence. Its no-argument dataset wrapper is another launcher profile, so it maps here instead of adding another CRC-32 package. See the pinned [cBench source](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/cBench/telecom_CRC32/src/crc_32.c).

All nine ports compute the same checksum over the byte-array contract:

| Language | Port |
|---|---|
| C | [`c/c/crc32.c`](../../../c/c/crc32.c) |
| C3 | [`c3/c/crc32.c3`](../../../c3/c/crc32.c3) |
| C++ | [`cpp/c/crc32.cpp`](../../../cpp/c/crc32.cpp) |
| Elisa | [`elisa/c/crc32.elisa`](../../../elisa/c/crc32.elisa) |
| Nim | [`nim/c/crc32.nim`](../../../nim/c/crc32.nim) |
| Odin | [`odin/c/crc32.odin`](../../../odin/c/crc32.odin) |
| Rust | [`rust/c/crc32.rs`](../../../rust/c/crc32.rs) |
| V | [`v/c/crc32.v`](../../../v/c/crc32.v) |
| Zig | [`zig/c/crc32.zig`](../../../zig/c/crc32.zig) |

## Pinned sources

- Java: [CRC32.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/CRC32.java)
- Python: [crc32.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/hashes/crc32.py)
- C alias: [hash_crc32.c](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/hash/hash_crc32.c)

See [`workload.json`](workload.json) for published examples and fixed test inputs. Build with `i64_array_scalar` and record with `benchmarks/run_i64_array_scalar.py`.
