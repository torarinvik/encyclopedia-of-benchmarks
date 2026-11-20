# Base58Check encoding

Encodes a bounded versioned byte payload as a checksummed Bitcoin Base58 string.

## Contract

The `i64_array_bytes_output` ABI accepts `[version_byte, payload_length, payload_byte_0, ...]`. The version and payload bytes are each in `0..255`; payload length is `0..32`; the frame has exactly `2 + payload_length` values. Maximum valid input length is 34 values, and the parse bound is 35 values so one trailing word can be rejected. A null or malformed input returns `-1`. The function concatenates version and payload, appends the first four bytes of double SHA-256, and writes the Bitcoin Base58 ASCII encoding. Each leading zero byte in the combined value is preserved as one leading `1`. Success returns the number of bytes written; a null or undersized output buffer returns `-2` without modifying it.

The maximum encoded output is 51 bytes. The first hash input is 1 to 33 bytes and the second is exactly 32 bytes, so every native port uses the same single 64-byte SHA-256 padding block and one compression pass per digest. Each port uses fixed local storage sized to this bounded profile.

## Algorithm and distinction

The profile includes three coupled steps: prefixing a version byte, truncating the second SHA-256 digest to four checksum bytes, and converting the full big-endian byte string to the Bitcoin alphabet while preserving all leading zeroes. This differs from generic digest/checksum benchmarks, which do not include the versioned Base58 transform, and from Base64/Base85 encoders, which use different alphabets and radices. The local file named `base58.py` is cataloged as a Base64 alias; it is not a Base58 implementation.

The RosettaCodeData title index was used only to discover the candidate. Algorithm semantics are cross-referenced with the [Bitcoin Wiki stable Base58Check revision](https://en.bitcoin.it/wiki/Base58Check?oldid=68948) and the [Bitcoin Core v28.0 encoder at commit `110183746150428e6385880c79f8c5733b1361ba`](https://github.com/bitcoin/bitcoin/blob/110183746150428e6385880c79f8c5733b1361ba/src/base58.cpp). No RosettaCode task prose, code, tests, or examples are reused. The workload uses standard interoperability known-answer outputs selected for empty, leading-zero, and maximum-output boundaries, plus locally authored malformed input frames.

## Workload and references

[`workload.json`](workload.json) covers empty and maximum-size payloads, the 51-byte output boundary, leading-zero preservation, invalid header and byte ranges, truncated and trailing frames including the maximum parseable frame, null input/output, and insufficient output capacity. [`primary_oracle.py`](primary_oracle.py) converts the byte string to an integer before repeated `divmod(58)`. [`independent_oracle.py`](independent_oracle.py) performs repeated division over a big-endian byte array. Both use Python's SHA-256 primitive for the checksum and have distinct Base58 conversion paths. `verify_workload.py` and `check_inventory.py` are static package helpers; neither was run during authoring.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/b/base58check_encode.c`](../../../c/b/base58check_encode.c) |
| C3 | [`c3/b/base58check_encode.c3`](../../../c3/b/base58check_encode.c3) |
| C++ | [`cpp/b/base58check_encode.cpp`](../../../cpp/b/base58check_encode.cpp) |
| Elisa | [`elisa/b/base58check_encode.elisa`](../../../elisa/b/base58check_encode.elisa) |
| Mojo | [`mojo/b/base58check_encode.mojo`](../../../mojo/b/base58check_encode.mojo) |
| Nim | [`nim/b/base58check_encode.nim`](../../../nim/b/base58check_encode.nim) |
| Odin | [`odin/b/base58check_encode.odin`](../../../odin/b/base58check_encode.odin) |
| Rust | [`rust/b/base58check_encode.rs`](../../../rust/b/base58check_encode.rs) |
| V | [`v/b/base58check_encode.v`](../../../v/b/base58check_encode.v) |
| Zig | [`zig/b/base58check_encode.zig`](../../../zig/b/base58check_encode.zig) |

The shared `i64_array_bytes_output` runner and verifier and the catalog now
register this package. Its 826-byte workspace cap includes the largest
one-block SHA-256 helper scratch area.
