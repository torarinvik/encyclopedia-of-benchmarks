# Translator

This benchmark ports `Translator.Translate` from the pinned
[TheAlgorithms/C-Sharp source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/DataCompression/Translator.cs).
The benchmark specializes the source's `Dictionary<string, string>` and text
to printable ASCII bytes so all nine implementations share the same
case-sensitive matching behavior.

## Contract

- ABI: `i64_array_bytes_output`. Input is packed as
  `[key_count, text_length, (key_length, value_length, key_bytes..., value_bytes...)*, text_bytes...]`.
  `key_count` is in `[0, 4]`; keys are unique, nonempty byte strings of length
  1..4; replacement values may be empty and have length 0..4; text length is
  0..64. All key, value, and text bytes must be printable ASCII `[32, 126]`.
  The packed input must have exactly the declared lengths. Maximum valid input
  is 106 signed 64-bit values; 107 values are parseable to check malformed
  framing.
- At each current text position, extend a substring by one byte at a time and
  take the first key that matches. This is the shortest matching key from that
  position, matching the source loop's earliest-ending hit. Append its
  replacement and continue after the matched key. If no key matches any prefix
  at the current position, drop the entire remaining suffix; the algorithm
  does not skip unmatched characters to search later text. Empty replacements
  still consume their matched key. Matching is case-sensitive.
- Output is the concatenation of replacement bytes for consumed matches, with
  no terminator. The output is at most 256 bytes and success returns its byte
  length. Invalid framing, duplicate keys, or out-of-domain bytes return `-1`.
  A null output pointer or insufficient capacity returns `-2` after input
  validation, without writing.
- The ASCII restriction makes each source C# UTF-16 code unit correspond to
  one benchmark byte. Non-ASCII strings and their UTF-16 indexing are outside
  this contract.

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/t/translator.c`](../../../c/t/translator.c) |
| C3 | [`c3/t/translator.c3`](../../../c3/t/translator.c3) |
| C++ | [`cpp/t/translator.cpp`](../../../cpp/t/translator.cpp) |
| Elisa | [`elisa/t/translator.elisa`](../../../elisa/t/translator.elisa) |
| Nim | [`nim/t/translator.nim`](../../../nim/t/translator.nim) |
| Odin | [`odin/t/translator.odin`](../../../odin/t/translator.odin) |
| Rust | [`rust/t/translator.rs`](../../../rust/t/translator.rs) |
| V | [`v/t/translator.v`](../../../v/t/translator.v) |
| Zig | [`zig/t/translator.zig`](../../../zig/t/translator.zig) |

## Workload and oracle

[`workload.json`](workload.json) covers empty maps and text, repeated and
multi-byte keys, shortest overlapping matches, empty replacement values,
unmatched leading and trailing text, maximum input and output sizes, malformed
framing, duplicate keys, non-ASCII bytes, and output-buffer errors. The
independent [oracle](../../translator_oracle.py) models the source's growing
substring scan and byte concatenation.

