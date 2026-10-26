# Two-dimensional scaled pattern matching

This package implements a bounded profile of the chapter's geometric pixel
model at one caller-supplied rational scale. Pattern cells are squares of side
`p/q`, placed with their origin at a text-grid corner. Each text pixel center
inside the scaled pattern area is mapped to the pattern square containing that
center; a placement matches when every such sampled text symbol equals its
mapped pattern symbol. The scale is supplied as integers, so all boundaries
and square mappings use exact integer arithmetic.

Input is `[height,width,pattern_height,pattern_width,p,q,text,pattern]`, with
row-major symbol arrays, text dimensions at most 12 by 12, pattern dimensions
at most 6 by 6, symbols in `[0,255]`, and `1 <= p/q <= 2`, `1 <= q <= 8`.
The scaled pattern's full rectangle must fit inside the text. Matching origins
are returned in row-major order as `[match_count,row_0,col_0,...]`. The maximum
result is 289 signed i64 values (2312 bytes). Invalid input returns `-1`;
null output or insufficient capacity returns `-2` without writing.

This is a fixed-scale matching profile: it does not search continuously over
all real scales or implement the chapter's faster all-scales algorithms. The
geometric center-sampling rule and all-placement output come from the chapter's
real-scale model; the bounds and supplied rational scale make the operation a
deterministic finite benchmark.

Source: “Two-Dimensional Scaled Pattern Matching,” *Encyclopedia of
Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_444`](https://doi.org/10.1007/978-1-4939-2864-4_444).
The ports and documentation are clean-room; no book prose or code was copied.

## Ports

| Language | Port |
|---|---|
| C | `c/t/two_dimensional_scaled_pattern_matching.c` |
| C3 | `c3/t/two_dimensional_scaled_pattern_matching.c3` |
| C++ | `cpp/t/two_dimensional_scaled_pattern_matching.cpp` |
| Elisa | `elisa/t/two_dimensional_scaled_pattern_matching.elisa` |
| Nim | `nim/t/two_dimensional_scaled_pattern_matching.nim` |
| Odin | `odin/t/two_dimensional_scaled_pattern_matching.odin` |
| Rust | `rust/t/two_dimensional_scaled_pattern_matching.rs` |
| V | `v/t/two_dimensional_scaled_pattern_matching.v` |
| Zig | `zig/t/two_dimensional_scaled_pattern_matching.zig` |

Primary exact-output oracle: `benchmarks/two_dimensional_scaled_pattern_matching_oracle.py`.
Independent verifier oracle: `benchmarks/two_dimensional_scaled_pattern_matching_verifier_oracle.py`.
