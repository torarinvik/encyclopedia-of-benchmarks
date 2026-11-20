# Tuned Boyer–Moore search

Find every byte-pattern occurrence with Hume and Sunday's Tuned Boyer–Moore
skip loop. A 128-entry bad-character table is built for the pattern. Its
final-byte shift is saved and the final-byte table entry is set to zero; a
bounded sentinel suffix of copies of the pattern's final byte ends the scan.
At each loop iteration, the implementation performs three table-driven
advances before checking the candidate's first `pattern_length - 1` bytes,
then applies the saved final-byte shift.

## Contract

- ABI: `int64_t tuned_boyer_moore_search(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)` (`i64_array_bytes_output`).
- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]`.
  Text length is 0..255; pattern length is 1..64; bytes are 0..127. The frame
  must contain exactly `2 + text_length + pattern_length` words. A valid frame
  has at most 321 words; the parse limit is 322 to reject one trailing word.
- Return every overlapping, zero-based match position in increasing order as
  little-endian signed 64-bit integers. At most 255 positions (2,040 bytes)
  are returned. An empty text or a pattern longer than the text has no matches.
- Empty patterns and malformed input return `-1`. Null output or insufficient
  capacity returns `-2` after input validation and search. A nonnull output is
  required even when no match is found; errors leave it untouched.
- For the valid `pattern_length > text_length` case, the profile returns an
  empty result without entering the sentinel loop. This avoids treating the
  virtual suffix as part of a real text window.

## Relationship to existing profiles

[`boyer_moore`](../../b/boyer_moore/README.md) combines bad-character and
good-suffix shifts at every alignment. [`horspool_search`](../../h/horspool_search/README.md)
uses a right-to-left comparison at each window. Tuned Boyer–Moore instead
uses a zeroed final-byte table entry and advances through three bad-character
shifts before verifying the candidate prefix. It does not use the Raita
last/first/middle probes or Turbo Boyer–Moore's remembered suffix state.

## Workload and references

[`workload.json`](workload.json) includes overlapping matches, a case that
requires three table advances before candidate verification, one-byte
patterns, an interior mismatch, embedded NUL and boundary bytes, empty text,
a longer pattern, malformed frames, and output errors. The primary reference
models the tuned sentinel skip loop. The independent reference checks each
complete text window directly.

The algorithm is described in the ESMAJ [Tuned Boyer–Moore page](https://igm.univ-mlv.fr/~lecroq/string/tunedbm.html),
with its bad-character preprocessing on the [Boyer–Moore page](https://igm.univ-mlv.fr/~lecroq/string/node14.html).
The primary research citation is Andrew Hume and Daniel Sunday, [“Fast String Searching”](https://doi.org/10.1002/spe.4380211105),
*Software: Practice and Experience* 21(11), 1991, pp. 1221–1248. These references provide algorithm
descriptions only; no source code or examples were copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/t/tuned_boyer_moore_search.c`](../../../c/t/tuned_boyer_moore_search.c) |
| C3 | [`c3/t/tuned_boyer_moore_search.c3`](../../../c3/t/tuned_boyer_moore_search.c3) |
| C++ | [`cpp/t/tuned_boyer_moore_search.cpp`](../../../cpp/t/tuned_boyer_moore_search.cpp) |
| Elisa | [`elisa/t/tuned_boyer_moore_search.elisa`](../../../elisa/t/tuned_boyer_moore_search.elisa) |
| Mojo | [`mojo/t/tuned_boyer_moore_search.mojo`](../../../mojo/t/tuned_boyer_moore_search.mojo) |
| Nim | [`nim/t/tuned_boyer_moore_search.nim`](../../../nim/t/tuned_boyer_moore_search.nim) |
| Odin | [`odin/t/tuned_boyer_moore_search.odin`](../../../odin/t/tuned_boyer_moore_search.odin) |
| Rust | [`rust/t/tuned_boyer_moore_search.rs`](../../../rust/t/tuned_boyer_moore_search.rs) |
| V | [`v/t/tuned_boyer_moore_search.v`](../../../v/t/tuned_boyer_moore_search.v) |
| Zig | [`zig/t/tuned_boyer_moore_search.zig`](../../../zig/t/tuned_boyer_moore_search.zig) |
