# Consistent overhead byte stuffing

Encode a bounded byte payload using basic COBS. The benchmark covers zero-run
boundaries, 254-byte code blocks, and the exact full-block terminal rule.

## Contract

- ABI: `i64_array_bytes_output`; symbol: `consistent_overhead_byte_stuffing`.
- Input is `[payload_byte_count, payload_bytes...]`. The count is in `0..=255`,
  each payload value is in `0..=255`, and the frame has exactly `count + 1`
  signed-i64 words.
- Output is the COBS byte stream without a framing delimiter. A valid empty
  payload encodes to one code byte, `01`.
- Invalid/null input returns `-1`. Null or short output returns `-2` without
  writes. Input validation precedes output-capacity checking.
- This is basic COBS, not the COBS/ZPE variant.

## Code blocks and bounds

The primary uses a streaming code placeholder. An ordinary code `1..254` is
followed by `code - 1` nonzero data bytes; when another code block follows, the
ordinary block represents an implicit zero. Code `255` is followed by exactly
254 nonzero data bytes and represents no zero. The terminal logical zero is
omitted when the payload naturally ends at a complete 254-byte `255` block,
which preserves the decoded bytes and canonical tight overhead bound.

At payload length `n=0`, output length is one. For `1<=n<=255`, output length
is at most `n + ceil(n/254)`, so the maximum is 257 bytes. Each port stages no
more than 257 output bytes and declares a 384-byte workspace allowance,
excluding caller-owned input and output.

The independent oracle first separates runs at zero bytes and encodes each
zero-terminated run as one or more code blocks. It does not share the primary's
placeholder-and-stream loop.

The algorithm follows Cheshire and Baker, [“Consistent Overhead Byte Stuffing,”
§III](https://doi.org/10.1109/90.769765), also available as the authors'
[paper PDF](https://stuartcheshire.org/papers/COBSforToN.pdf). The pinned
[RosettaCodeData popular-title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
is used for title discovery only. See [RIGHTS.md](RIGHTS.md).

The [workload](workload.json) pins empty and zero-containing payloads, an exact
254-byte block, a block followed by one additional byte, malformed inputs, and
null/short-output errors. It is registered with the `i64_array_bytes_output`
runner and verifier.

## Language ports

| Language | Source |
|---|---|
| C | [c/c/consistent_overhead_byte_stuffing.c](../../../c/c/consistent_overhead_byte_stuffing.c) |
| C3 | [c3/c/consistent_overhead_byte_stuffing.c3](../../../c3/c/consistent_overhead_byte_stuffing.c3) |
| C++ | [cpp/c/consistent_overhead_byte_stuffing.cpp](../../../cpp/c/consistent_overhead_byte_stuffing.cpp) |
| Elisa | [elisa/c/consistent_overhead_byte_stuffing.elisa](../../../elisa/c/consistent_overhead_byte_stuffing.elisa) |
| Mojo | [mojo/c/consistent_overhead_byte_stuffing.mojo](../../../mojo/c/consistent_overhead_byte_stuffing.mojo) |
| Nim | [nim/c/consistent_overhead_byte_stuffing.nim](../../../nim/c/consistent_overhead_byte_stuffing.nim) |
| Odin | [odin/c/consistent_overhead_byte_stuffing.odin](../../../odin/c/consistent_overhead_byte_stuffing.odin) |
| Rust | [rust/c/consistent_overhead_byte_stuffing.rs](../../../rust/c/consistent_overhead_byte_stuffing.rs) |
| V | [v/c/consistent_overhead_byte_stuffing.v](../../../v/c/consistent_overhead_byte_stuffing.v) |
| Zig | [zig/c/consistent_overhead_byte_stuffing.zig](../../../zig/c/consistent_overhead_byte_stuffing.zig) |

Both references, workload helper, and inventory helper were authored for static
review. No programs, tests, or helpers have been run.
