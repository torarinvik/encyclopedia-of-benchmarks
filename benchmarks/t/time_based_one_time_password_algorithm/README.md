# Time-based one-time password with HMAC-SHA-1

This package measures one deterministic TOTP calculation. Its input contains
the secret as bytes and a Unix timestamp; the algorithm reads no clock and
does no validation-window or provisioning work.

## Contract

The `i64_array_bytes_output` symbol is
`time_based_one_time_password_algorithm`. Input is
`[key_length, key_byte_0, ..., key_byte_(key_length-1), unix_seconds]` with a
key of 16–64 bytes, each in `0..255`, and a nonnegative signed-i64 timestamp.
The valid frame has exactly `key_length+2` words; the maximum valid and
parseable lengths are 66 and 67 words.

The 16-byte minimum follows HOTP's 128-bit shared-key requirement in
[RFC 4226 §4](https://www.rfc-editor.org/rfc/rfc4226.html). The moving factor
is `floor(unix_seconds/30)` using T0=0, serialized as an
8-byte big-endian counter. HMAC-SHA-1 is dynamically truncated as specified
for HOTP, reduced modulo 1,000,000, and emitted as exactly six ASCII digits.
Leading zeroes are retained. Invalid input returns `-1`; null or short output
returns `-2`. Both errors leave output untouched.

The profile excludes clock reads, time drift windows, OTP validation,
resynchronization, key provisioning, URI handling, and alternate hash or digit
settings. The native ports implement SHA-1 compression and HMAC locally so
each language measures the complete TOTP kernel; the standalone SHA-1
benchmark is not linked as a dependency.

## Algorithm and references

The primary oracle uses Python's `hmac` and `hashlib.sha1`. The independent
oracle implements the fixed-block SHA-1 compression and HMAC construction
directly, with separate state and padding code. Both apply the same TOTP
counter rule and decimal truncation.

Normative references: [RFC 6238, §4](https://www.rfc-editor.org/rfc/rfc6238.html)
defines the time-derived counter and its 30-second default;
[RFC 4226, §§4 and 5.3](https://www.rfc-editor.org/rfc/rfc4226.html) specifies
HOTP's minimum key length and dynamic truncation. The workload includes one explicitly identified
RFC 6238 Appendix B known-answer-derived fixture; no source implementation,
task wording, or task code is copied. Rosetta Code is used only to identify
the benchmark title gap. The pinned six-digit result is derived from the
RFC's eight-digit Appendix B SHA-1 vector: `94287082 mod 1,000,000 = 287082`.
The maximum-frame fixture extends that key with zero bytes to a 64-byte key;
HMAC normalizes both keys to the same 64-byte block, so its expected digits
are identical.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md), and
[`INVENTORY.md`](INVENTORY.md). Package-local reference and inventory helpers
are source artifacts and have not been run.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/t/time_based_one_time_password_algorithm.c`](../../../c/t/time_based_one_time_password_algorithm.c) |
| C3 | [`c3/t/time_based_one_time_password_algorithm.c3`](../../../c3/t/time_based_one_time_password_algorithm.c3) |
| C++ | [`cpp/t/time_based_one_time_password_algorithm.cpp`](../../../cpp/t/time_based_one_time_password_algorithm.cpp) |
| Elisa | [`elisa/t/time_based_one_time_password_algorithm.elisa`](../../../elisa/t/time_based_one_time_password_algorithm.elisa) |
| Mojo | [`mojo/t/time_based_one_time_password_algorithm.mojo`](../../../mojo/t/time_based_one_time_password_algorithm.mojo) |
| Nim | [`nim/t/time_based_one_time_password_algorithm.nim`](../../../nim/t/time_based_one_time_password_algorithm.nim) |
| Odin | [`odin/t/time_based_one_time_password_algorithm.odin`](../../../odin/t/time_based_one_time_password_algorithm.odin) |
| Rust | [`rust/t/time_based_one_time_password_algorithm.rs`](../../../rust/t/time_based_one_time_password_algorithm.rs) |
| V | [`v/t/time_based_one_time_password_algorithm.v`](../../../v/t/time_based_one_time_password_algorithm.v) |
| Zig | [`zig/t/time_based_one_time_password_algorithm.zig`](../../../zig/t/time_based_one_time_password_algorithm.zig) |
