# Two-dimensional exact string matching

This bounded profile implements the chapter's two-dimensional Bird–Baker
reduction. It first marks where each pattern row occurs in each text row, then
uses KMP over the sequence of pattern rows at each horizontal start column.
This preserves row ordering and reports matches by increasing start column,
then increasing start row.

Input is `[text_rows,text_cols,pattern_rows,pattern_cols,text...,pattern...]`,
with each dimension in `[1,8]`, the pattern no larger than the text, and
symbols in `[0,3]`. Output is `[match_count,row_0,col_0,...]`, with zero-based
coordinates in column-major start order, as little-endian signed i64 values.
Invalid input returns `-1`;
null output or insufficient capacity returns `-2` without writing.

Source: “Multidimensional String Matching,” DOI
[`10.1007/978-1-4939-2864-4_247`](https://doi.org/10.1007/978-1-4939-2864-4_247).
This profile fixes the two-dimensional case and uses a bounded direct row
matcher before the KMP row-sequence phase; it does not include the chapter's
higher-dimensional generalizations.

| Language | Port |
|---|---|
| C | `c/t/two_dimensional_string_matching.c` |
| C3 | `c3/t/two_dimensional_string_matching.c3` |
| C++ | `cpp/t/two_dimensional_string_matching.cpp` |
| Elisa | `elisa/t/two_dimensional_string_matching.elisa` |
| Nim | `nim/t/two_dimensional_string_matching.nim` |
| Odin | `odin/t/two_dimensional_string_matching.odin` |
| Rust | `rust/t/two_dimensional_string_matching.rs` |
| V | `v/t/two_dimensional_string_matching.v` |
| Zig | `zig/t/two_dimensional_string_matching.zig` |
