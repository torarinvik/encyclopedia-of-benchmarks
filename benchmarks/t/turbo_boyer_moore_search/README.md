# Turbo Boyer–Moore search

Find every occurrence of a nonempty byte pattern in a bounded text using the
Turbo Boyer–Moore algorithm. The scan compares from right to left, remembers
the suffix that matched on the previous attempt, skips comparisons inside
that known factor, and combines turbo, bad-character, and good-suffix shifts.

## Contract

- ABI: `int64_t turbo_boyer_moore_search(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)` (`i64_array_bytes_output`).
- Input is `[text_length, pattern_length, text_bytes..., pattern_bytes...]`.
  Text length is 0..255; pattern length is 1..64; each byte is 0..127. The
  frame must contain exactly `2 + text_length + pattern_length` words. The
  maximum valid frame is 321 words and the parseable cap is 322 to reject one
  trailing word.
- Return all zero-based matching start positions in increasing order as
  little-endian signed 64-bit integers. Matches may overlap. A pattern longer
  than the text and a text with no match return an empty result (0 bytes).
  There can be at most 255 matches, so output is at most 2,040 bytes.
- Empty patterns and malformed frames return `-1`. A null output pointer or
  insufficient capacity returns `-2` without writes; a nonnull output pointer
  is required even when there are no matches. Input validation and searching
  precede output validation.
- The primary uses a fixed 128-byte alphabet table, Boyer–Moore good-suffix
  preprocessing, and Turbo BM's remembered-suffix state. Its input bounds keep
  the text, pattern, match-position list, and output storage fixed.

## Relationship to local search profiles

[`boyer_moore`](../../b/boyer_moore/README.md) combines bad-character and
good-suffix shifts but does not retain a matched suffix across attempts.
[`boyer_moore_search`](../../b/boyer_moore_search/README.md) uses only the bad-character
rule, [`boyer_moore_ag`](../../b/boyer_moore_ag/README.md) keeps Apostolico–Giancarlo
skip state, and [`horspool_search`](../../h/horspool_search/README.md) uses
Horspool shifts. Turbo BM specifically remembers the suffix matched on the
previous attempt and may skip that factor or apply a turbo shift. The package
returns all match positions so overlap handling and post-match memory are
included in the measured operation.

## Workload and references

[`workload.json`](workload.json) covers overlapping and repeated matches,
right-to-left mismatches, empty text, a pattern longer than the text, ASCII
NUL and boundary bytes, malformed frames, and output-buffer errors. The
primary reference follows the Turbo BM state machine and reuses the
remembered suffix only after the corresponding shift. The independent
reference checks every possible text window directly.

The ESMAJ [Turbo-BM description](https://igm.univ-mlv.fr/~lecroq/string/node15.html)
specifies the search state and shifts; its [Boyer–Moore description](https://igm.univ-mlv.fr/~lecroq/string/node14.html)
specifies the preprocessing tables. The primary research source is Crochemore
et al., [“Speeding Up Two String-Matching Algorithms”](https://doi.org/10.1007/BF01185427),
*Algorithmica* 12(4/5), 1994, pp. 247–267. These sources are used for
algorithm descriptions only. No source code, examples, or test data were
copied.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/t/turbo_boyer_moore_search.c`](../../../c/t/turbo_boyer_moore_search.c) |
| C3 | [`c3/t/turbo_boyer_moore_search.c3`](../../../c3/t/turbo_boyer_moore_search.c3) |
| C++ | [`cpp/t/turbo_boyer_moore_search.cpp`](../../../cpp/t/turbo_boyer_moore_search.cpp) |
| Elisa | [`elisa/t/turbo_boyer_moore_search.elisa`](../../../elisa/t/turbo_boyer_moore_search.elisa) |
| Mojo | [`mojo/t/turbo_boyer_moore_search.mojo`](../../../mojo/t/turbo_boyer_moore_search.mojo) |
| Nim | [`nim/t/turbo_boyer_moore_search.nim`](../../../nim/t/turbo_boyer_moore_search.nim) |
| Odin | [`odin/t/turbo_boyer_moore_search.odin`](../../../odin/t/turbo_boyer_moore_search.odin) |
| Rust | [`rust/t/turbo_boyer_moore_search.rs`](../../../rust/t/turbo_boyer_moore_search.rs) |
| V | [`v/t/turbo_boyer_moore_search.v`](../../../v/t/turbo_boyer_moore_search.v) |
| Zig | [`zig/t/turbo_boyer_moore_search.zig`](../../../zig/t/turbo_boyer_moore_search.zig) |
