# Weighted greedy set cover

This package implements the chapter's weighted greedy set-cover rule. At each
step it chooses a set minimizing its nonnegative weight divided by the number
of currently uncovered elements it would cover. The chosen set is added and
the process stops when all elements are covered. Ratio comparisons use exact
integer cross-products; equal ratios are broken by the lowest set ID.

Input is `[universe_size, set_count, set_weights..., set_masks...]`. The
universe and set counts are each in `1..16`; weights are in `0..10000`; masks
must refer only to universe elements. The union of all sets must cover the
universe. Output is `[selected_count, selected_set_ids_in_greedy_order...]`
as little-endian signed i64 values. Invalid input, including an uncoverable
universe, returns `-1`; null output or capacity below
`8*(selected_count+1)` returns `-2` without writing. Maximum output is 136
bytes.

The exported symbol is `weighted_greedy_set_cover`; the ABI is
`i64_array_bytes_output`. The [workload](workload.json) includes exact-ratio
ties, zero costs, the maximum universe/set count, malformed masks, uncoverable
input, and output-capacity probes.

The profile selects the exact weighted Chvátal greedy rule described in
“Greedy Set-Cover Algorithms,” Neal E. Young, *Encyclopedia of Algorithms*,
DOI [`10.1007/978-1-4939-2864-4_175`](https://doi.org/10.1007/978-1-4939-2864-4_175).
It does not implement the chapter's broader submodular generalization,
max-coverage, or VC-dimension-specific results. The source chapter is used
only to define the algorithm; ports are clean-room implementations.

The [primary oracle](../../weighted_greedy_set_cover_oracle.py) uses
cross-multiplication. The [independent verifier](../../weighted_greedy_set_cover_verifier_oracle.py)
uses exact rational-number comparisons with a separate set representation.

| Language | Port |
|---|---|
| C | [`weighted_greedy_set_cover.c`](../../../c/g/weighted_greedy_set_cover.c) |
| C3 | [`weighted_greedy_set_cover.c3`](../../../c3/g/weighted_greedy_set_cover.c3) |
| C++ | [`weighted_greedy_set_cover.cpp`](../../../cpp/g/weighted_greedy_set_cover.cpp) |
| Elisa | [`weighted_greedy_set_cover.elisa`](../../../elisa/g/weighted_greedy_set_cover.elisa) |
| Nim | [`weighted_greedy_set_cover.nim`](../../../nim/g/weighted_greedy_set_cover.nim) |
| Odin | [`weighted_greedy_set_cover.odin`](../../../odin/g/weighted_greedy_set_cover.odin) |
| Rust | [`weighted_greedy_set_cover.rs`](../../../rust/g/weighted_greedy_set_cover.rs) |
| V | [`weighted_greedy_set_cover.v`](../../../v/g/weighted_greedy_set_cover.v) |
| Zig | [`weighted_greedy_set_cover.zig`](../../../zig/g/weighted_greedy_set_cover.zig) |
