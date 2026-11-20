# Weighted set-cover domination reduction

This package benchmarks a bounded, clean-room presolve pass for weighted set
cover. It applies the row-domination, simple-column-domination, and advanced
column-domination rules described in “Set Cover with Almost Consecutive Ones,”
*Encyclopedia of Algorithms*, entry 368
([chapter DOI](https://doi.org/10.1007/978-1-4939-2864-4_368)). It measures the
reductions only; it does not test the almost-consecutive-ones property or run
the chapter's set-cover solver.

## Input and output

The ABI input is the signed i64 array
`[row_count, column_count, weight_0, ..., weight_(n-1), row_mask_0, ..., row_mask_(m-1)]`.
There are 1–8 rows and columns, every weight is 1–20, and bit `j` in a row mask
indicates that original column `j` covers that row. The exact input length is
`2 + column_count + row_count`, at most 18 words. A 19-word parseable frame is
allowed so trailing input can be rejected explicitly.

Successful output is a little-endian signed i64 vector:
`[reduced_row_count, reduced_column_count, row_ids[], column_ids[], column_weights[], reduced_row_masks[]]`.
IDs are zero-based original indices in ascending order. Output masks use
compact bit positions corresponding to the retained columns in `column_ids`.
The largest result is 272 bytes. Invalid or null input returns `-1`; null or
short output returns `-2`. Input validation happens before output-buffer
validation, and errors leave the output unchanged.

## Reduction profile

Each pass scans in this order and applies at most one deletion:

1. **Row domination:** for active rows `i` and `j`, if the active column set of
   `i` is a subset of `j`'s, delete `j`. Equal sets keep the lower original
   row ID.
2. **Simple column domination:** delete `c1` when its active-row coverage is a
   subset of `c2`'s and `weight(c1) >= weight(c2)`. Equal coverages and weights
   keep the lower original column ID.
3. **Advanced column domination:** consider distinct `c1` and `c2` only when
   their active-row coverages overlap. For every row covered by `c1` but not
   `c2`, select the minimum-weight active column covering that row; equal
   minimum weights select the lower original column ID. Let `X` be the set of
   selected columns, with duplicates counted once. Delete `c1` when
   `weight(c1) >= weight(c2) + sum(weight(x) for x in X)`.

Pairs are visited in ascending original-ID order. After any deletion, scanning
restarts at row domination. The process stops when no rule applies. All
weights are positive. Empty rows remain in the reduced instance, preserving
infeasibility; retained IDs and masks make the reduction result reconstructible.

## Workload and references

[`workload.json`](workload.json) contains each expected byte frame, maximum
valid and parseable inputs, and invalid/null/short-output cases. The primary
bit-mask reference is [`primary_oracle.py`](primary_oracle.py). The independent
set-based reference is [`independent_oracle.py`](independent_oracle.py); it
also exhaustively compares the minimum cover cost before and after reduction.
[`verify_workload.py`](verify_workload.py) contains the static inventory and
fixture review entry point. No benchmark or port execution is needed to inspect
these package artifacts.

The primary implementation uses fixed-size masks and scans up to `n` candidate
minimum-weight columns for each of up to `m` exclusive rows in every advanced
candidate pair. With at most `m+n` deletions, its conservative bound is
`O((m+n) m n^3)` time and `O(m+n)` auxiliary space. The independent optimum
check is `O(2^n m)` for each of the original and reduced instances.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/set_cover_domination_reduction.c](../../../c/s/set_cover_domination_reduction.c) |
| C3 | [c3/s/set_cover_domination_reduction.c3](../../../c3/s/set_cover_domination_reduction.c3) |
| C++ | [cpp/s/set_cover_domination_reduction.cpp](../../../cpp/s/set_cover_domination_reduction.cpp) |
| Elisa | [elisa/s/set_cover_domination_reduction.elisa](../../../elisa/s/set_cover_domination_reduction.elisa) |
| Mojo | [mojo/s/set_cover_domination_reduction.mojo](../../../mojo/s/set_cover_domination_reduction.mojo) |
| Nim | [nim/s/set_cover_domination_reduction.nim](../../../nim/s/set_cover_domination_reduction.nim) |
| Odin | [odin/s/set_cover_domination_reduction.odin](../../../odin/s/set_cover_domination_reduction.odin) |
| Rust | [rust/s/set_cover_domination_reduction.rs](../../../rust/s/set_cover_domination_reduction.rs) |
| V | [v/s/set_cover_domination_reduction.v](../../../v/s/set_cover_domination_reduction.v) |
| Zig | [zig/s/set_cover_domination_reduction.zig](../../../zig/s/set_cover_domination_reduction.zig) |
