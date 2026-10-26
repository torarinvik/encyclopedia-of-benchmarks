# FM-index backward-search count

This bounded profile builds the sentinel BWT of a short text and counts one
pattern using the FM-index backward-search interval. It covers the `count(P)`
operation described in Encyclopedia of Algorithms chapters 82 and 83. It does
not implement suffix-array locate samples, substring display, or the chapters'
compressed-space and query-time guarantees.

## Contract

The `i64_array_bytes_output` input is `[n, text[0..n), m, pattern[0..m)]`.
Text and pattern symbols are integers 1 through 4; symbol 0 is reserved for a
unique smallest sentinel appended to the text. `1 <= n <= 32` and `1 <= m <= 8`.
The result is an eight-byte little-endian signed count. The internal suffix
array is built by lexicographically sorting the suffixes of `text + [0]`; the
BWT is its preceding-symbol column. For each pattern symbol in reverse order,
the inclusive-exclusive suffix interval is refined with `C[c] + rank_c(x)`.
Overlapping occurrences are counted. Invalid input returns `-1`; null output
or capacity below eight bytes returns `-2`, after input validation. Errors do
not write output.

The bounded implementation uses a direct prefix scan for rank and a simple
suffix sort. This preserves FM-index semantics while making no asymptotic
performance or compressed-space claim.

## Source scope

- DOI 10.1007/978-1-4939-2864-4_82, `OEBPS/AChap82.html`: the FM-index section
  gives the BWT, `C`/rank LF mapping, and backward interval updates for
  `count(P)`.
- DOI 10.1007/978-1-4939-2864-4_83, `OEBPS/AChap83.html`: the chapter names the
  Ferragina–Manzini FM-index as a compressed text index supporting pattern
  counting, locating, and display. This package covers only counting.

This is a clean-room implementation of the stated operations; no book prose,
figures, or code are copied. See [`workload.json`](workload.json), the primary
FM-index oracle at [`benchmarks/fm_index_count_oracle.py`](../../fm_index_count_oracle.py),
and the independent direct-search verifier at
[`benchmarks/fm_index_count_verifier_oracle.py`](../../fm_index_count_verifier_oracle.py).

## Language ports

| Language | Port |
|---|---|
| C | [`c/f/fm_index_count.c`](../../../c/f/fm_index_count.c) |
| C3 | [`c3/f/fm_index_count.c3`](../../../c3/f/fm_index_count.c3) |
| C++ | [`cpp/f/fm_index_count.cpp`](../../../cpp/f/fm_index_count.cpp) |
| Elisa | [`elisa/f/fm_index_count.elisa`](../../../elisa/f/fm_index_count.elisa) |
| Nim | [`nim/f/fm_index_count.nim`](../../../nim/f/fm_index_count.nim) |
| Odin | [`odin/f/fm_index_count.odin`](../../../odin/f/fm_index_count.odin) |
| Rust | [`rust/f/fm_index_count.rs`](../../../rust/f/fm_index_count.rs) |
| V | [`v/f/fm_index_count.v`](../../../v/f/fm_index_count.v) |
| Zig | [`zig/f/fm_index_count.zig`](../../../zig/f/fm_index_count.zig) |
