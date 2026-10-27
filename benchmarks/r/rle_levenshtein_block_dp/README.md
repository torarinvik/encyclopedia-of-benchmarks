# Run-length encoded Levenshtein block dynamic programming

This profile computes unit-cost Levenshtein edit distance on two
run-length-encoded strings. It partitions the dynamic-programming table into
one block for each pair of runs. Each block consumes top and left boundary
values, computes the bottom and right boundaries, and passes them to adjacent
blocks. The input remains run-length encoded; the ports do not construct the
expanded strings or return an edit script.

Input is `[left_run_count,(symbol,length)*,right_run_count,(symbol,length)*]`.
Each side has one to four runs, symbols are in `0..3`, run lengths are in
`1..8`, and each encoded string expands to at most 16 symbols. The recurrence
minimizes deletion and insertion costs of one and a substitution cost of zero
for equal symbols or one otherwise. Malformed input returns `-1`.

This is distinct from [rle_lcs_block_dp](../rle_lcs_block_dp/README.md): LCS
and Levenshtein have different cell recurrences and different distance
objectives, despite sharing the run-pair block layout. It is also distinct
from ordinary-input [levenshtein_distance](../../l/levenshtein_distance/README.md),
which does not process compressed runs or propagate run-block boundaries.
The chapter's weighted-edit algorithms are not ported because it reports two
different methods and scoring parameters without giving either recurrence;
its affine-gap algorithm is described through a DAG/path transformation but
the new recurrence is not stated; and its Lempel–Ziv section gives a phrase
block framing and cited results without defining the phrase-level updates.

Source: “Similarity Between Compressed Strings,” Jin Wook Kim, Amihood Amir,
Gad M. Landau, and Kunsoo Park, *Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_375`](https://doi.org/10.1007/978-1-4939-2864-4_375).
See [RIGHTS.md](RIGHTS.md) for attribution.

The primary oracle propagates run-pair block boundaries. The independent
verifier computes the full edit-distance table while reading encoded symbols
on demand. The [workload](workload.json) covers one-run cases, block-boundary
propagation, a maximum-size input, and malformed inputs.

| Language | Port |
|---|---|
| C | `c/r/rle_levenshtein_block_dp.c` |
| C3 | `c3/r/rle_levenshtein_block_dp.c3` |
| C++ | `cpp/r/rle_levenshtein_block_dp.cpp` |
| Elisa | `elisa/r/rle_levenshtein_block_dp.elisa` |
| Nim | `nim/r/rle_levenshtein_block_dp.nim` |
| Odin | `odin/r/rle_levenshtein_block_dp.odin` |
| Rust | `rust/r/rle_levenshtein_block_dp.rs` |
| V | `v/r/rle_levenshtein_block_dp.v` |
| Zig | `zig/r/rle_levenshtein_block_dp.zig` |
