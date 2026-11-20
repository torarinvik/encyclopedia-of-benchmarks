# Punycode encoding of Unicode scalar sequences

This package measures RFC 3492 Punycode encoding for a bounded sequence of
integer Unicode scalar values. The encoder preserves basic ASCII code points
at the start, then represents non-basic code points by insertion deltas in
generalized variable-length digits with adaptive bias.

## Contract

The ABI is `i64_array_bytes_output`; the exported symbol is
`punycode_codepoint_sequence_encode`. Input is
`[count, codepoint_0, ..., codepoint_(count-1)]`, where `0<=count<=32`. Every
code point must be in `0..0x10FFFF` and outside the UTF-16 surrogate interval
`0xD800..0xDFFF`. The maximum valid input is 33 signed-i64 words; 34 words are
parseable so a trailing-word frame can be rejected. A null input or malformed
frame returns `-1`.

The return value is the number of output bytes, and the output is the RFC
Punycode payload without an IDNA `xn--` prefix. RFC 3492 appends the `-`
delimiter whenever at least one basic code point was copied, including the
all-basic case. An empty sequence succeeds with zero output bytes. A null
output or insufficient capacity returns `-2` when the encoded payload is
nonempty; errors write no bytes. The profile performs no normalization,
case-folding, label splitting, IDNA processing, or domain validation.

The 320-byte output cap is conservative. With at most 32 scalar values, each
non-basic insertion delta is below `10^8`: the largest code-point gap is at
most `0x10FFFF-0x80`, multiplied by at most 32, plus at most 32 increments
for earlier points. Each continued generalized digit divides the remaining
value by at least 10, so at most nine digits encode one non-basic point. If
all 32 points are non-basic, the digit output is at most 288 bytes. If both
basic and non-basic points occur, with `k<=31` non-basic points, the output is
at most `9k+(32-k)+1 = 33+8k <= 281` bytes, including the delimiter. The
all-basic case emits at most 33 bytes, including its delimiter. Native
workspace is one 320-byte staging buffer; it is committed only after input
validation and output-capacity checks.

## Algorithm and references

The primary reference follows RFC 3492 sections 3–6, using code points in
increasing order, generalized variable-length integer encoding, and bias
adaptation. The independent oracle obtains bytes from Python's built-in
`punycode` codec and decodes those bytes with a separate insertion-state
decoder, checking that they recover the original scalar sequence.

Normative source: A. Costello, [RFC 3492, “Punycode: A Bootstring encoding of
Unicode for Internationalized Domain Names in Applications”](https://www.rfc-editor.org/rfc/rfc3492.html),
sections 3–6. The GitHub [Punycode.js repository](https://github.com/mathiasbynens/punycode.js)
was used as a discovery reference. No code, prose, task examples, or tests are
copied.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), and
[`INVENTORY.md`](INVENTORY.md). The references and static package inventory
helper are package-local and were not run. The package is registered with the
shared `i64_array_bytes_output` runner and independent verifier.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/p/punycode_codepoint_sequence_encode.c`](../../../c/p/punycode_codepoint_sequence_encode.c) |
| C3 | [`c3/p/punycode_codepoint_sequence_encode.c3`](../../../c3/p/punycode_codepoint_sequence_encode.c3) |
| C++ | [`cpp/p/punycode_codepoint_sequence_encode.cpp`](../../../cpp/p/punycode_codepoint_sequence_encode.cpp) |
| Elisa | [`elisa/p/punycode_codepoint_sequence_encode.elisa`](../../../elisa/p/punycode_codepoint_sequence_encode.elisa) |
| Mojo | [`mojo/p/punycode_codepoint_sequence_encode.mojo`](../../../mojo/p/punycode_codepoint_sequence_encode.mojo) |
| Nim | [`nim/p/punycode_codepoint_sequence_encode.nim`](../../../nim/p/punycode_codepoint_sequence_encode.nim) |
| Odin | [`odin/p/punycode_codepoint_sequence_encode.odin`](../../../odin/punycode_codepoint_sequence_encode.odin) |
| Rust | [`rust/p/punycode_codepoint_sequence_encode.rs`](../../../rust/p/punycode_codepoint_sequence_encode.rs) |
| V | [`v/p/punycode_codepoint_sequence_encode.v`](../../../v/punycode_codepoint_sequence_encode.v) |
| Zig | [`zig/p/punycode_codepoint_sequence_encode.zig`](../../../zig/p/punycode_codepoint_sequence_encode.zig) |
