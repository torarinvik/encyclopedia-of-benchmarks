# Approximate tandem K-edit repeats

This package enumerates factors satisfying the chapter's K-edit repeat
definition. A factor is split as `v' w1 … wℓ v''`, with at least two nonempty
middle pieces. The profile minimizes
`ed(v', suffix(w1)) + Σ ed(wi, wi+1) + ed(prefix(wℓ), v'')`
over all such partitions and all suffix/prefix fragments, including empty
fragments. It emits each qualifying factor once, with its minimum cost.

## Contract

ABI: `i64_array_bytes_output`; symbol: `approximate_tandem_k_edit_repeats`.
Input is `[n,K,symbols[n]]`, with `2<=n<=12`, `0<=K<=4`, and symbols in
`0..3`; exact input length is `n+2` (at most 14 words). Output is little-endian
signed-64 data `[record_count,(zero_based_start,length,minimum_edit_cost)...]`,
ordered by start then length. At most 66 factors can be emitted, so output is
bounded by 1,592 bytes. Invalid input returns `-1`; null output or insufficient
capacity returns `-2` without writes. Workspace is bounded at 4,096 bytes.

The ports directly enumerate bounded partitions and use ordinary unit-cost
Levenshtein distance. They do not claim the chapter's `O(n+K²)` algorithm or
its implementation details. This profile is distinct from the Hamming-based
approximate-square, K-repetition, and K-run profiles.

## Source and rights

Gregory Kucherov and Dina Sokol, “Approximate Tandem Repeats,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_24`](https://doi.org/10.1007/978-1-4939-2864-4_24),
Definition 3. The chapter is copyrighted and grants no source-code license.
These ports are clean-room bounded enumerators; see [`RIGHTS.md`](RIGHTS.md).

Oracles:
[`approximate_tandem_k_edit_repeats_oracle.py`](../../approximate_tandem_k_edit_repeats_oracle.py)
and
[`approximate_tandem_k_edit_repeats_verifier_oracle.py`](../../approximate_tandem_k_edit_repeats_verifier_oracle.py).

| Language | Port |
|---|---|
| C | [`c/a/approximate_tandem_k_edit_repeats.c`](../../../c/a/approximate_tandem_k_edit_repeats.c) |
| C3 | [`c3/a/approximate_tandem_k_edit_repeats.c3`](../../../c3/a/approximate_tandem_k_edit_repeats.c3) |
| C++ | [`cpp/a/approximate_tandem_k_edit_repeats.cpp`](../../../cpp/a/approximate_tandem_k_edit_repeats.cpp) |
| Elisa | [`elisa/a/approximate_tandem_k_edit_repeats.elisa`](../../../elisa/a/approximate_tandem_k_edit_repeats.elisa) |
| Nim | [`nim/a/approximate_tandem_k_edit_repeats.nim`](../../../nim/a/approximate_tandem_k_edit_repeats.nim) |
| Odin | [`odin/a/approximate_tandem_k_edit_repeats.odin`](../../../odin/a/approximate_tandem_k_edit_repeats.odin) |
| Rust | [`rust/a/approximate_tandem_k_edit_repeats.rs`](../../../rust/a/approximate_tandem_k_edit_repeats.rs) |
| V | [`v/a/approximate_tandem_k_edit_repeats.v`](../../../v/a/approximate_tandem_k_edit_repeats.v) |
| Zig | [`zig/a/approximate_tandem_k_edit_repeats.zig`](../../../zig/a/approximate_tandem_k_edit_repeats.zig) |
