# Two-dimensional optimal-expected exact matching

This profile implements the static-grid test-point method of Kärkkäinen and
Ukkonen for finding all exact occurrences of a square pattern in a square
text. It places a regular grid of test positions, indexes the pattern's
overlapping linear templates, and verifies each distinct candidate against
the complete pattern. The four-symbol workload fixes the sample length to
`ceil(log_4(m²))` and template spacing to `floor(m / sample_length)`.

Input is `[text_side,pattern_side,text...,pattern...]`, with
`1 <= pattern_side <= text_side <= 12` and symbols in `[0,3]`. Both matrices
are row-major. Output is `[match_count,(row,column)...]` as little-endian
signed 64-bit values, ordered by increasing row and then column. Invalid
input returns `-1`; a null output or insufficient capacity returns `-2`
without writing output.

Pattern preprocessing and storage use `O(m²)` space. The method has expected
search time `O(n² log_4(m²)/m²)` under the paper's uniform independent-symbol
model; this bounded implementation can take `O(n²m²)` time in the worst case
because it verifies every distinct candidate. Its fixed workspace is 8 KiB.

This is a distinct method from the repository's [Bird–Baker row reduction
profile](../two_dimensional_string_matching/README.md), which uses KMP across
pattern rows. The separate [one-mismatch linear-template profile](../two_dimensional_k_mismatch_linear_templates/README.md)
implements the paper's `k=1`, `p=1` approximate extension and returns both
exact and one-mismatch windows.

Sources: Kärkkäinen and Ukkonen, [“Two- and Higher-Dimensional Pattern
Matching in Optimal Expected Time”](https://doi.org/10.1137/S0097539794275872),
and [“Multidimensional String Matching,” Encyclopedia of
Algorithms](https://doi.org/10.1007/978-1-4939-2864-4_247). The ports are
clean-room implementations of the algorithm descriptions; no source code or
protected text was reused.

| Language | Port |
|---|---|
| C | `c/t/two_dimensional_optimal_expected_matching.c` |
| C3 | `c3/t/two_dimensional_optimal_expected_matching.c3` |
| C++ | `cpp/t/two_dimensional_optimal_expected_matching.cpp` |
| Elisa | `elisa/t/two_dimensional_optimal_expected_matching.elisa` |
| Mojo | `mojo/t/two_dimensional_optimal_expected_matching.mojo` |
| Nim | `nim/t/two_dimensional_optimal_expected_matching.nim` |
| Odin | `odin/t/two_dimensional_optimal_expected_matching.odin` |
| Rust | `rust/t/two_dimensional_optimal_expected_matching.rs` |
| V | `v/t/two_dimensional_optimal_expected_matching.v` |
| Zig | `zig/t/two_dimensional_optimal_expected_matching.zig` |

The bounded byte-output workload and both references are registered in the
repository suite. No port has been compiled or run.
