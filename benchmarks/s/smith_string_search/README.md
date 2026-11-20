# Smith string search

Find every occurrence of a byte pattern using Smith's combined skip rule. At
each candidate window, compare the full pattern; then advance by the larger of
the Horspool shift for the window's final byte and the Quick Search shift for
the byte immediately after the window.

## Contract

- ABI: `int64_t smith_string_search(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)` (`i64_array_bytes_output`).
- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]`.
  Text length is 0..255; pattern length is 1..64; byte values are 0..127. The
  frame must contain exactly `2 + text_length + pattern_length` words. A valid
  frame has at most 321 words; the parser accepts at most 322 to detect one
  trailing word.
- Return every overlapping, zero-based match position in increasing order as
  little-endian signed 64-bit integers. At most 255 positions (2,040 bytes)
  are returned. Empty text and a longer pattern have no matches.
- Empty patterns and malformed input return `-1`. Null output or insufficient
  capacity returns `-2` after input validation and search. A nonnull output is
  required even when no match is found; errors leave it untouched.
- The byte 128 is reserved as a virtual end-of-text lookahead symbol. Its
  Quick Search shift is the default `pattern_length + 1`, so the final valid
  alignment needs no read beyond the input frame.

## Relationship to existing profiles

[`horspool_search`](../../h/horspool_search/README.md) uses only the bad-byte
shift from the end of the current window. [`quick_search`](../../q/quick_search/README.md)
uses only the lookahead byte after the window. Smith combines those two
independently computed shifts with their maximum. The result is distinct from
the locally available component profiles and from Boyer–Moore variants such
as [`raita_search`](../../r/raita_search/README.md).

## Workload and references

[`workload.json`](workload.json) covers cases where each component shift wins,
overlapping results, one-byte patterns, embedded NUL and boundary bytes, empty
text, a longer pattern, malformed frames, and output errors. The primary
reference performs Smith's table preprocessing and combined-shift scan. The
independent reference checks every possible window directly.

The algorithm and its two preprocessing tables are described by the ESMAJ
[Smith algorithm](https://igm.univ-mlv.fr/~lecroq/string/node21.html),
[Horspool algorithm](https://igm.univ-mlv.fr/~lecroq/string/node18.html), and
[Quick Search algorithm](https://igm.univ-mlv.fr/~lecroq/string/node19.html)
pages. The primary research citation is P. D. Smith, [“Experiments with a very
fast substring search algorithm”](https://doi.org/10.1002/spe.4380211006),
*Software: Practice and Experience* 21(10), 1991, pp. 1065–1074. These sources
provide algorithm descriptions only; no code, examples, or test data were
copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/s/smith_string_search.c`](../../../c/s/smith_string_search.c) |
| C3 | [`c3/s/smith_string_search.c3`](../../../c3/s/smith_string_search.c3) |
| C++ | [`cpp/s/smith_string_search.cpp`](../../../cpp/s/smith_string_search.cpp) |
| Elisa | [`elisa/s/smith_string_search.elisa`](../../../elisa/s/smith_string_search.elisa) |
| Mojo | [`mojo/s/smith_string_search.mojo`](../../../mojo/s/smith_string_search.mojo) |
| Nim | [`nim/s/smith_string_search.nim`](../../../nim/s/smith_string_search.nim) |
| Odin | [`odin/s/smith_string_search.odin`](../../../odin/s/smith_string_search.odin) |
| Rust | [`rust/s/smith_string_search.rs`](../../../rust/s/smith_string_search.rs) |
| V | [`v/s/smith_string_search.v`](../../../v/s/smith_string_search.v) |
| Zig | [`zig/s/smith_string_search.zig`](../../../zig/s/smith_string_search.zig) |
