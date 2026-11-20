# Shift-And matching in LZW-compressed text

This benchmark profiles Kida, Takeda, Shinohara, and Arikawa's bit-parallel
Shift-And matcher over an LZW code stream. It reconstructs the phrase
dictionary and stores per-phrase Shift-And and occurrence summaries, so it
reports every match without expanding the complete text. This is a separate
algorithm and compressed format from the local KMP `Jump`/`Output` profile for
straight-line programs.

## Contract

The ABI is `i64_array_bytes_output`; symbol: `lzw_compressed_shift_and_matching`.
Input is `[alphabet_size,pattern_length,code_count,pattern...,codes...]`.
`alphabet_size` is 1 through 16, `pattern_length` is 1 through 32, and
`code_count` is 0 through 32. Pattern symbols are integers in
`[0,alphabet_size)`. The first code, when present, must name an initial
single-symbol phrase.

The dictionary starts with code `a` denoting the one-symbol phrase `[a]` for
each alphabet symbol `a`. For each later code, an index below the next unused
code selects an existing phrase. A code equal to the next unused code selects
the LZW special case `previous_phrase + first(previous_phrase)`. A code above
the next unused code is malformed. After resolving the current phrase, the
decoder dictionary adds `previous_phrase + first(current_phrase)`; in the
special case this is the phrase just resolved. Input framing must contain
exactly `3 + pattern_length + code_count` signed-i64 words.

Output is `[match_count,zero_based_start_offsets...]` as little-endian signed
i64 words, with offsets in ascending order. An empty code stream succeeds with
`[0]`. Malformed input returns `-1`; a null output or insufficient capacity
returns `-2`. Errors write no bytes. The maximum decoded length for 32 codes is
528 symbols, so the maximum output is 4,232 bytes including the count word.
The bounded mask width follows the paper's `pattern_length <= 32` assumption.

For the bound, the initial dictionary phrases have length one. Each decoded
code adds at most one dictionary phrase, formed by extending the previous
decoded phrase by one symbol; after the j-th code, every phrase that can be
selected is therefore at most j symbols long. With 32 codes, total expanded
length is at most `1+2+...+32 = 528`. Output order follows phrase boundaries:
matches crossing the current boundary start after every match already
contained in the preceding text; fully internal matches start at or after the
boundary. The internal ancestor chain is emitted from the shortest matching
prefix to the longest. Thus each phrase contributes starts in ascending order.

The primary reference reconstructs the LZW dictionary and composes its
per-phrase Shift-And, crossing-boundary, and in-phrase occurrence summaries.
The independent reference decodes the bounded code stream and checks each
candidate start by direct symbol comparison. The latter is only an oracle; it
does not describe the measured algorithm.

## Source

- Kida, Takeda, Shinohara, and Arikawa, “Shift-And Approach to Pattern
  Matching in LZW Compressed Text,” CPM 1999, Figure 4 and Lemmas 2–6:
  [author-hosted paper](https://www.iss.is.tohoku.ac.jp/~ayumi/papers/CPM99_lzw.pdf).
- Takeda and Shinohara, “Pattern Matching on Compressed Text,” *Encyclopedia
  of Algorithms*, DOI [10.1007/978-1-4939-2864-4_81](https://doi.org/10.1007/978-1-4939-2864-4_81).

Only algorithm ideas are used. This is a clean-room bounded profile, not a
reproduction of the paper's implementation or experimental claims.

## Package files

- [Primary phrase-summary reference](../../lzw_compressed_shift_and_matching_oracle.py)
- [Independent decode-and-scan reference](../../lzw_compressed_shift_and_matching_verifier_oracle.py)
- [Workload](workload.json)
- [Rights and provenance](RIGHTS.md)
- Static package inventory: `check_inventory.py`

## Language ports

| Language | Port |
|---|---|
| C | [`c/l/lzw_compressed_shift_and_matching.c`](../../../c/l/lzw_compressed_shift_and_matching.c) |
| C3 | [`c3/l/lzw_compressed_shift_and_matching.c3`](../../../c3/l/lzw_compressed_shift_and_matching.c3) |
| C++ | [`cpp/l/lzw_compressed_shift_and_matching.cpp`](../../../cpp/l/lzw_compressed_shift_and_matching.cpp) |
| Elisa | [`elisa/l/lzw_compressed_shift_and_matching.elisa`](../../../elisa/l/lzw_compressed_shift_and_matching.elisa) |
| Mojo | [`mojo/l/lzw_compressed_shift_and_matching.mojo`](../../../mojo/l/lzw_compressed_shift_and_matching.mojo) |
| Nim | [`nim/l/lzw_compressed_shift_and_matching.nim`](../../../nim/l/lzw_compressed_shift_and_matching.nim) |
| Odin | [`odin/l/lzw_compressed_shift_and_matching.odin`](../../../odin/l/lzw_compressed_shift_and_matching.odin) |
| Rust | [`rust/l/lzw_compressed_shift_and_matching.rs`](../../../rust/l/lzw_compressed_shift_and_matching.rs) |
| V | [`v/l/lzw_compressed_shift_and_matching.v`](../../../v/l/lzw_compressed_shift_and_matching.v) |
| Zig | [`zig/l/lzw_compressed_shift_and_matching.zig`](../../../zig/l/lzw_compressed_shift_and_matching.zig) |

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run.
