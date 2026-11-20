# Raita string search

Find every occurrence of a nonempty byte pattern with Raita's tuned
Boyer–Moore–Horspool search. At each window, compare the final pattern byte,
then the first byte, then the byte at `pattern_length / 2`, and finally the
interior bytes from index 1 through `pattern_length - 2`. Shift each window
with the Horspool table indexed by the text byte at the window's end.

## Contract

- ABI: `int64_t raita_search(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)` (`i64_array_bytes_output`).
- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]`.
  Text length is 0..255; pattern length is 1..64; bytes are 0..127. The
  packed frame must contain exactly `2 + text_length + pattern_length` words.
  The maximum valid frame is 321 words; implementations accept at most 322
  words for parsing so that a single trailing word is rejected safely.
- Return all overlapping, zero-based match positions in increasing order as
  little-endian signed 64-bit integers. The maximum output is 255 positions,
  or 2,040 bytes. A pattern longer than the text has no matches.
- Empty patterns and malformed inputs return `-1`. Null output or insufficient
  capacity returns `-2`, after input validation and search. Output must be
  nonnull even when the result is empty; errors leave it untouched.
- For one- and two-byte patterns, the interior comparison range is empty.
  The first and middle probes may repeat an earlier probe, matching the
  algorithm's specified order (`middle = pattern_length / 2`).

## Relationship to existing profiles

[`horspool_search`](../../h/horspool_search/README.md) uses the same bad-byte
shift table but compares from the end of the pattern leftward. Raita adds
last/first/middle probes before verifying the remaining interior bytes. This
profile preserves that comparison order while returning all overlapping
positions. It is distinct from local [`boyer_moore_horspool`](../../b/boyer_moore_horspool/README.md),
which also searches from the right, and from Turbo Boyer–Moore, which retains
matched-suffix state and uses good-suffix shifts.

## Workload and references

[`workload.json`](workload.json) covers overlapping matches, each of Raita's
early probes, an interior mismatch after those probes pass, pattern lengths
one and two, empty text, a longer pattern, ASCII NUL and boundary values,
malformed frames, and output errors. The primary reference follows Raita's
probe order and Horspool shift table. The independent reference compares each
candidate window directly.

Raita's algorithm is described in the ESMAJ [Raita page](https://igm.univ-mlv.fr/~lecroq/string/node22.html).
The primary research source is Timo Raita, [“Tuning the Boyer–Moore–Horspool
String Searching Algorithm”](https://doi.org/10.1002/spe.4380221006),
*Software: Practice and Experience* 22(10), 1992, pp. 879–884. The
[Boyer–Moore page](https://igm.univ-mlv.fr/~lecroq/string/node14.html)
describes the shared bad-character table. These sources provide algorithm
descriptions only; no source code or examples were copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/r/raita_search.c`](../../../c/r/raita_search.c) |
| C3 | [`c3/r/raita_search.c3`](../../../c3/r/raita_search.c3) |
| C++ | [`cpp/r/raita_search.cpp`](../../../cpp/r/raita_search.cpp) |
| Elisa | [`elisa/r/raita_search.elisa`](../../../elisa/r/raita_search.elisa) |
| Mojo | [`mojo/r/raita_search.mojo`](../../../mojo/r/raita_search.mojo) |
| Nim | [`nim/r/raita_search.nim`](../../../nim/r/raita_search.nim) |
| Odin | [`odin/r/raita_search.odin`](../../../odin/r/raita_search.odin) |
| Rust | [`rust/r/raita_search.rs`](../../../rust/r/raita_search.rs) |
| V | [`v/r/raita_search.v`](../../../v/r/raita_search.v) |
| Zig | [`zig/r/raita_search.zig`](../../../zig/r/raita_search.zig) |
