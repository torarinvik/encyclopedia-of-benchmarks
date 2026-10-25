# MiBench security SHA (SHA-0)

This package covers the pre-SHA-1 160-bit hash selected by the pinned MiBench
launcher. The source wraps the schedule update in `#ifdef USE_MODIFIED_SHA`;
`MiBench/security-sha/info.sh` does not define that macro. The resulting
schedule is the unrotated SHA-0 recurrence. Local [`sha1`](../sha1/README.md)
uses the SHA-1 schedule, which rotates each expanded word left by one bit, so
it is a different algorithm.

## Contract

The `i64_array_bytes_output` ABI accepts `[message_length, message_bytes...]`.
The message length is 0–55, the array must contain exactly one length value
plus the payload, and payload values must be bytes. The limit keeps padding and
the message in one 512-bit block. The function returns the 20-byte raw digest
in big-endian word order. Invalid input returns `-1`; a null or undersized
output buffer returns `-2` without writes.

The MiBench driver streams a file and prints five hexadecimal words. This
package isolates its SHA-0 core as a bounded arbitrary-byte call and returns
raw bytes. The independent Python oracle implements the compression recurrence
and padding directly. Standard empty-message and `abc` SHA-0 vectors are in
[`workload.json`](workload.json).

## Provenance and rights

Pinned source snapshot: [`lac-dcc/Benchmarks` at
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/MiBench/security-sha).
The source headers identify the implementation as the NIST Secure Hash
Algorithm, heavily modified by Uwe Hollerbach from Peter C. Gutmann's
implementation as found in Bruce Schneier's *Applied Cryptography*. The pinned
`LICENSE` file contains these attribution comments but states no explicit
license or redistribution grant. The ports are independently written from the
SHA-0 algorithm definition and do not copy the upstream C implementation; no
license is asserted for the upstream files.

The pinned cBench `security_sha` launcher also leaves
`USE_MODIFIED_SHA` undefined and its corresponding source has the same
unrotated message schedule. It is therefore the same SHA-0 algorithm profile,
not SHA-1; its file-I/O wrapper is excluded here. Both launchers and source
paths are recorded in the workload metadata.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/s/mibench_security_sha0.c](../../../c/s/mibench_security_sha0.c) |
| C3 | [c3/s/mibench_security_sha0.c3](../../../c3/s/mibench_security_sha0.c3) |
| C++ | [cpp/s/mibench_security_sha0.cpp](../../../cpp/s/mibench_security_sha0.cpp) |
| Elisa | [elisa/s/mibench_security_sha0.elisa](../../../elisa/s/mibench_security_sha0.elisa) |
| Nim | [nim/s/mibench_security_sha0.nim](../../../nim/s/mibench_security_sha0.nim) |
| Odin | [odin/s/mibench_security_sha0.odin](../../../odin/s/mibench_security_sha0.odin) |
| Rust | [rust/s/mibench_security_sha0.rs](../../../rust/s/mibench_security_sha0.rs) |
| V | [v/s/mibench_security_sha0.v](../../../v/s/mibench_security_sha0.v) |
| Zig | [zig/s/mibench_security_sha0.zig](../../../zig/s/mibench_security_sha0.zig) |

The independent oracle is [`mibench_security_sha0_oracle.py`](../../mibench_security_sha0_oracle.py).
