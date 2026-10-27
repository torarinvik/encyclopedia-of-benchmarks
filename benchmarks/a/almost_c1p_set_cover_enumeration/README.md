# Set Cover Enumeration for Almost Consecutive Ones

This bounded profile implements the chapter's explicit row-wise enumeration
of feasible partial covers from “Set Cover with Almost Consecutive Ones,”
Michael Dom, *Encyclopedia of Algorithms*, DOI
10.1007/978-1-4939-2864-4_368. Starting with the empty partial cover, it
processes rows in order. For each partial cover that misses the current row,
it adds one version for every column covering that row and removes the old
uncovered partial cover. At the end it selects a minimum-weight feasible
cover.

## Contract

The ABI is `i64_array_bytes_output`. Input is
`[row_count,column_count,weight_0,...,weight_(n-1),row_mask_0,...,row_mask_(m-1)]`.
There are 1–8 rows and 1–10 columns; each column weight is an integer in
`[1,20]`. Bit `j` of a row mask is 1 exactly when column `j` covers that row.
The input matrix is therefore a compact representation of the chapter's
binary incidence matrix. A zero row is valid but makes the instance
uncoverable.

For a feasible instance the output is
`[selected_count,selected_column_indices...,total_weight]`, with zero-based
column indices in increasing order. Among equal-cost covers the smallest
numeric column bitmask wins. If no cover exists, output is `[-1]`. Malformed
input returns `-1`; null or undersized output returns `-2` without writes.
Positive weights and at most eight rows bound a minimum cover to at most eight
selected columns, so output is at most 80 bytes.

This package covers the explicit feasible-solution enumeration core. The
chapter's row/column/advanced-column reductions, strong-C1P performance
guarantee, and Ruf–Schöbel branch-and-bound method are separate procedures and
are not included here. The profile is an exact bounded search and is distinct
from [weighted greedy set cover](../weighted_greedy_set_cover/README.md).

## Files

Nine ports are under `c/a`, `cpp/a`, `rust/a`, `c3/a`, `nim/a`, `odin/a`,
`elisa/a`, `v/a`, and `zig/a`, with a workload and independent oracles.

## Source and rights

Michael Dom, “Set Cover with Almost Consecutive Ones,” *Encyclopedia of
Algorithms*, DOI [`10.1007/978-1-4939-2864-4_368`](https://doi.org/10.1007/978-1-4939-2864-4_368).
The chapter describes the row-wise enumeration but grants no source-code
license. The ports are clean-room implementations; see [RIGHTS.md](RIGHTS.md).
The package includes its [workload](workload.json), [primary oracle](../../almost_c1p_set_cover_enumeration_oracle.py),
and [independent verifier](../../almost_c1p_set_cover_enumeration_verifier_oracle.py).
