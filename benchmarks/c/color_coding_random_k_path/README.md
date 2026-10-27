# Color Coding randomized k-path replay

This package profiles the chapter's randomized outer loop for finding a simple path with `k` vertices using color coding, DOI [`10.1007/978-1-4939-2864-4_76`](https://doi.org/10.1007/978-1-4939-2864-4_76). The existing [`color_coding_k_path`](../color_coding_k_path/README.md) profile tests one supplied coloring and returns a Boolean. This profile processes an ordered tape of colorings and returns a witness from the first successful trial.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[n,m,k,trial_count,edge_pairs[2m],colors[trial_count*n]]`. Each coloring is one row in trial order; color IDs are in `[0,k)`.
- Bounds: `1 <= n <= 12`, `0 <= m <= 66`, `1 <= k <= min(6,n)`, `1 <= trial_count <= 8`. The graph is simple and undirected; edges are zero-based vertex pairs. Maximum input length is 232 words.
- For each trial, run the subset/endpoint DP for a colorful path of exactly `k` vertices. Stop at the first trial with such a path. Among paths in a successful trial, return the lexicographically smallest vertex sequence.
- Output on success is `[1,one_based_trial_index,path_vertex_0,...,path_vertex_(k-1)]`; output when no trial succeeds is `[0,0]`. Words are little-endian signed-i64 values. Maximum output is 64 bytes. Invalid input returns `-1`; null output or insufficient capacity returns `-2` without writing.

Each coloring row represents one random assignment from the chapter's color-coding method. Supplying the draws makes a single call reproducible; the profile does not generate randomness or claim an expected-time/probability guarantee. It is distinct from the local single-coloring Boolean subroutine because it runs the trial loop and returns a path witness.

## Provenance and rights

Source: “Color Coding,” *Encyclopedia of Algorithms*, DOI `10.1007/978-1-4939-2864-4_76`, describing random vertex coloring and colorful-path detection. The chapter grants no source-code license. All ports and oracles are clean-room implementations from the described behavior; no book prose, figures, or code are reproduced. See [`RIGHTS.md`](RIGHTS.md).

## Files

- [`workload.json`](workload.json)
- [Primary subset/endpoint DP oracle](../../color_coding_random_k_path_oracle.py)
- [Independent DFS verifier oracle](../../color_coding_random_k_path_verifier_oracle.py)

| Language | Port |
|---|---|
| C | [`c/c/color_coding_random_k_path.c`](../../../c/c/color_coding_random_k_path.c) |
| C3 | [`c3/c/color_coding_random_k_path.c3`](../../../c3/c/color_coding_random_k_path.c3) |
| C++ | [`cpp/c/color_coding_random_k_path.cpp`](../../../cpp/c/color_coding_random_k_path.cpp) |
| Elisa | [`elisa/c/color_coding_random_k_path.elisa`](../../../elisa/c/color_coding_random_k_path.elisa) |
| Nim | [`nim/c/color_coding_random_k_path.nim`](../../../nim/c/color_coding_random_k_path.nim) |
| Odin | [`odin/c/color_coding_random_k_path.odin`](../../../odin/c/color_coding_random_k_path.odin) |
| Rust | [`rust/c/color_coding_random_k_path.rs`](../../../rust/c/color_coding_random_k_path.rs) |
| V | [`v/c/color_coding_random_k_path.v`](../../../v/c/color_coding_random_k_path.v) |
| Zig | [`zig/c/color_coding_random_k_path.zig`](../../../zig/c/color_coding_random_k_path.zig) |
