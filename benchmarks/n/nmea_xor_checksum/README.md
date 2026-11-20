# NMEA payload XOR checksum

Compute the NMEA 8-bit XOR checksum over a bounded sentence payload. This is
the protocol checksum reduction itself, distinct from the local
[hash_xor8](../../h/hash_xor8/README.md) benchmark, whose routine adds bytes
and applies two's-complement finalization despite its name. It also has a
different computation from Internet checksum, Fletcher, Adler, and CRC.

## Contract

The i64_array_scalar input is [L, byte_0, ..., byte_(L-1)]. The payload is
the sentence content after its start delimiter and before *; framing,
checksum digits, and line endings are excluded. L is in 0..=76, each byte
is in 0..=127, and the full array length must be exactly L+1. Return the
bitwise XOR of all payload bytes, or -1 for null, malformed, or out-of-range
input. An empty payload returns zero. The 76-byte payload ceiling follows the
protocol's 82-byte sentence maximum after allowing for the start delimiter,
*, two checksum digits, and CR/LF.

The primary is a left-to-right XOR fold. The independent reference counts the
parity of each of the seven possible payload bits. Both run in O(L) time and
use O(1) auxiliary space.

Protocol provenance: GPSD, [NMEA Revealed — NMEA Encoding Conventions](https://gpsd.gitlab.io/gpsd/NMEA.html).
That page specifies an 8-bit XOR over sentence characters excluding framing
and checksum delimiters and gives the maximum sentence length. This package
uses those facts to define a clean-room payload-only API. See [RIGHTS.md](RIGHTS.md)
for source-use notes.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/n/nmea_xor_checksum.c](../../../c/n/nmea_xor_checksum.c) |
| C3 | [c3/n/nmea_xor_checksum.c3](../../../c3/n/nmea_xor_checksum.c3) |
| C++ | [cpp/n/nmea_xor_checksum.cpp](../../../cpp/n/nmea_xor_checksum.cpp) |
| Elisa | [elisa/n/nmea_xor_checksum.elisa](../../../elisa/n/nmea_xor_checksum.elisa) |
| Mojo | [mojo/n/nmea_xor_checksum.mojo](../../../mojo/n/nmea_xor_checksum.mojo) |
| Nim | [nim/n/nmea_xor_checksum.nim](../../../nim/n/nmea_xor_checksum.nim) |
| Odin | [odin/n/nmea_xor_checksum.odin](../../../odin/n/nmea_xor_checksum.odin) |
| Rust | [rust/n/nmea_xor_checksum.rs](../../../rust/n/nmea_xor_checksum.rs) |
| V | [v/n/nmea_xor_checksum.v](../../../v/n/nmea_xor_checksum.v) |
| Zig | [zig/n/nmea_xor_checksum.zig](../../../zig/n/nmea_xor_checksum.zig) |

The bounded fixtures are in [workload.json](workload.json). Suite registration
is tracked in [ALGORITHM_EXPANSION_COVERAGE.md](../../ALGORITHM_EXPANSION_COVERAGE.md).
