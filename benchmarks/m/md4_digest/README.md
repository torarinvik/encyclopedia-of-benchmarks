# MD4 digest

This benchmark computes one MD4 digest over a bounded byte message. The input
is a signed 64-bit array framed as `[n, byte_0, ..., byte_(n-1)]`, with
`0 <= n <= 4096`, each byte in `0..255`, and exact array length `n + 1`.
An input with more than 4,097 words is rejected; 4,098 words are parseable so
the suite can test a trailing value. The ABI result is `16` on success, `-1`
for malformed input, and `-2` for a valid message with a null output or fewer
than 16 output bytes. Input errors take precedence, and errors leave output
untouched.

The result is the 16 raw digest bytes. Each of the four final 32-bit chaining
words is serialized least-significant byte first. The implementation applies
all additions modulo `2^32`, interprets each block as sixteen little-endian
words, appends `0x80`, zero-fills to byte offset 56 in the final 64-byte
block, and appends the original bit length as an eight-byte little-endian
integer. A 4,096-byte message occupies at most 65 padded blocks. Ports stream
one 64-byte block at a time; the stated 512-byte workspace cap includes the
16-word block (64 bytes), chaining and working states (32 bytes), possible
output staging (16 bytes), length/index variables, and alignment. The
remaining allowance keeps the same explicit ceiling across compiler ABIs.

The primary reference assembles padded words on demand and applies each
operation to its explicit target register. The independent reference builds
the complete padded message and advances the four register names cyclically
through the three rounds. Package workload validation compares both
references on every fixture, including lengths 55, 56, 63, 64, 65, and 4,096.
Boundary messages use the deterministic byte pattern `(37*i + 11) mod 256`;
the workload stores this compact recipe and expands it before suite recording.

## Sources and security status

RFC 1320 supplies the algorithm definition used for the clean-room ports:
[RFC 1320](https://www.rfc-editor.org/rfc/rfc1320), especially its padding,
word ordering, round functions, and digest serialization sections. The
[RosettaCodeData pinned popular-task index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used only to discover the title “MD4”; no task page content, code, text,
examples, or tests are reused. RFC 6150 later moved MD4 to Historic and
describes known security weaknesses. This is an algorithm benchmark, not a
recommendation to use MD4 for security-sensitive applications:
[RFC 6150](https://www.rfc-editor.org/rfc/rfc6150).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/md4_digest.c`](../../../c/m/md4_digest.c) |
| C++ | [`cpp/m/md4_digest.cpp`](../../../cpp/m/md4_digest.cpp) |
| Rust | [`rust/m/md4_digest.rs`](../../../rust/m/md4_digest.rs) |
| Elisa | [`elisa/m/md4_digest.elisa`](../../../elisa/m/md4_digest.elisa) |
| C3 | [`c3/m/md4_digest.c3`](../../../c3/m/md4_digest.c3) |
| Nim | [`nim/m/md4_digest.nim`](../../../nim/m/md4_digest.nim) |
| Odin | [`odin/m/md4_digest.odin`](../../../odin/m/md4_digest.odin) |
| V | [`v/m/md4_digest.v`](../../../v/m/md4_digest.v) |
| Zig | [`zig/m/md4_digest.zig`](../../../zig/m/md4_digest.zig) |
| Mojo | [`mojo/m/md4_digest.mojo`](../../../mojo/m/md4_digest.mojo) |

The exported functions use the repository's `i64_array_bytes_output` ABI.
Elisa keeps its raw pointer use at the FFI boundary and uses bounded views for
the message and block processing.
