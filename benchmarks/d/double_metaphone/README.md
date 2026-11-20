# Double Metaphone

Encode a bounded name into the primary and optional alternate phonetic keys
defined by Lawrence Philips's 1998/1999 implementation and published 2000
article. The implementation uses an ordered, context-sensitive scan: spelling
groups and their surrounding letters select output symbols, may emit different
primary and alternate fragments, and may advance past letters consumed by a
group. This profile keeps the original four-symbol key limit and the explicit
Latin-1 `Ç` and `Ñ` cases.

## Contract

The `i64_array_bytes_output` input is `[byte_length, byte_0, ..., byte_n]`.
The byte length is 0 through 32. Accepted bytes are ASCII letters, ASCII
space, and Latin-1 `Ç`, `ç`, `Ñ`, or `ñ` (`0xC7`, `0xE7`, `0xD1`, `0xF1`).
ASCII and Latin-1 lowercase letters are converted to uppercase before scanning;
spaces remain in place because they affect prefix and context rules. No Unicode
transcoding, trimming, or collapsing of spaces is performed.

The frame has 1 through 33 signed 64-bit words when valid and at most 34 words
when parseable. The first word must equal the number of remaining bytes, and
the frame must contain exactly that many bytes. Null input, truncated or
trailing frames, lengths outside 0 through 32, and bytes outside the accepted
set return `-1`.

Output is the variable byte sequence
`[primary_length, secondary_length, primary_bytes..., secondary_bytes...]`.
Each key length is 0 through 4, and the return value is the number of bytes
written, including both length bytes. A zero secondary length means that no
distinct alternate key is present. Empty input is valid and returns two zero
length bytes. For valid input, null output or insufficient output capacity
returns `-2` without writing. Input validation takes precedence: invalid input
returns `-1` even if the output pointer is null or the capacity is too small.

The scanner begins after a silent initial consonant in `GN`, `KN`, `PN`, `WR`,
or `PS`; initial `X` emits the algorithm's S-equivalent. It processes input
from left to right while either key is shorter than four symbols. Lookahead
outside the input is treated as a space, as in Philips's padded scan. The
Slavo-Germanic flag is set when the normalized input contains `W`, `K`, `CZ`,
or `WITZ`. All per-letter context tests, including the special prefix
conditions, are pinned to the original version described above. Other
punctuation and all other non-ASCII bytes are outside this benchmark profile.

The fixed state workspace is capped at 80 bytes across the ten ports. The
largest state layout uses a 37-byte normalized buffer (32 input bytes plus
five lookahead spaces), two four-byte keys, three machine-word length counters,
and a flag: 70 bytes of fields before alignment, at most 80 bytes after
internal and tail padding in the current field order.
ABI input and output buffers and language runtime call frames are excluded. No
dynamic workspace is needed by the algorithm.

## References and provenance

The full branch behavior is derived from Philips's original C++ source archive
and checked against the description and `C` case in the 2000 article. The
independent comparison reference is Apache Commons Codec's implementation; the
profile follows Philips's original four-symbol behavior and explicit Latin-1
cases rather than importing later extensions. See [`RIGHTS.md`](RIGHTS.md) for
the source and license record, [`workload.json`](workload.json) for independent
fixtures, and [`INVENTORY.md`](INVENTORY.md) for the static package inventory.

The two reference traversals are independently structured. The primary
reference uses a state object with focused per-letter consumers. The second
reference expresses each scan step as a selected rule action and separately
serializes the resulting keys. Both are original implementations of the
published behavior; neither is a copy of Philips's or Apache's source.

## Language ports

| Language | Source |
|---|---|
| C | [`double_metaphone.c`](../../../c/d/double_metaphone.c) |
| C3 | [`double_metaphone.c3`](../../../c3/d/double_metaphone.c3) |
| C++ | [`double_metaphone.cpp`](../../../cpp/d/double_metaphone.cpp) |
| Elisa | [`double_metaphone.elisa`](../../../elisa/d/double_metaphone.elisa) |
| Mojo | [`double_metaphone.mojo`](../../../mojo/d/double_metaphone.mojo) |
| Nim | [`double_metaphone.nim`](../../../nim/d/double_metaphone.nim) |
| Odin | [`double_metaphone.odin`](../../../odin/d/double_metaphone.odin) |
| Rust | [`double_metaphone.rs`](../../../rust/d/double_metaphone.rs) |
| V | [`double_metaphone.v`](../../../v/d/double_metaphone.v) |
| Zig | [`double_metaphone.zig`](../../../zig/d/double_metaphone.zig) |
