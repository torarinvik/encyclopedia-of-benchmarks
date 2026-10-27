# Run-length encoded LCS block dynamic programming

This profile computes the longest common subsequence length of two
run-length-encoded strings by partitioning the dynamic-programming table into
one block for each pair of runs. Each block consumes its top and left boundary,
computes its lower and right boundaries, and passes those boundaries to the
neighboring blocks. Input remains in run-length form; the ports do not build
ordinary expanded strings. The implementation stores only block boundaries
and temporary state for one bounded block at a time.

Input is `[left_run_count,(symbol,length)*,right_run_count,(symbol,length)*]`.
Each side has one to four runs, symbols are in `0..3`, run lengths are in
`1..8`, and each encoded string expands to at most 16 symbols. The result is
the LCS length, in `0..16`; malformed input returns `-1`. The recurrence is
the standard LCS cell recurrence applied within each run-pair block. This
bounded implementation uses one cell update per position in a block; it does
not claim the asymptotic bounds of the chapter's cited compressed-string
algorithms. The output is only the length, so equivalent optimal subsequences
do not require a tie rule.

This is distinct from [longest_common_subsequence](../../l/longest_common_subsequence/README.md),
whose inputs are ordinary ASCII sequences and whose port uses a single-row DP.
The package follows the chapter's compressed-input block decomposition and
boundary propagation. It covers only run-length encoded LCS. The distinct
run-length Levenshtein profile is implemented in
[rle_levenshtein_block_dp](../rle_levenshtein_block_dp/README.md). Weighted
edit, affine-gap, and Lempel–Ziv methods remain outside the bounded suite
because the chapter does not state a concrete recurrence or phrase-update
procedure for them.

Source: “Similarity Between Compressed Strings,” Jin Wook Kim, Amihood Amir,
Gad M. Landau, and Kunsoo Park, *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_375`](https://doi.org/10.1007/978-1-4939-2864-4_375).
See [RIGHTS.md](RIGHTS.md) for attribution.

The primary oracle uses run-pair block boundaries. The independent verifier
uses a full-table recurrence with run symbols read on demand, without creating
expanded input strings. The [workload](workload.json) includes single-block,
multi-block, boundary-propagation, maximum-size, and malformed cases.

| Language | Port |
|---|---|
| C | `c/r/rle_lcs_block_dp.c` |
| C3 | `c3/r/rle_lcs_block_dp.c3` |
| C++ | `cpp/r/rle_lcs_block_dp.cpp` |
| Elisa | `elisa/r/rle_lcs_block_dp.elisa` |
| Nim | `nim/r/rle_lcs_block_dp.nim` |
| Odin | `odin/r/rle_lcs_block_dp.odin` |
| Rust | `rust/r/rle_lcs_block_dp.rs` |
| V | `v/r/rle_lcs_block_dp.v` |
| Zig | `zig/r/rle_lcs_block_dp.zig` |
