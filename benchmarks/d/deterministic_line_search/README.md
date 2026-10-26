# Deterministic doubling search on a line

This package models the deterministic doubling strategy described in “Deterministic Searching on the Line,” *Encyclopedia of Algorithms* (DOI [10.1007/978-1-4939-2864-4_106](https://doi.org/10.1007/978-1-4939-2864-4_106)). Starting at the origin, the searcher explores alternating directions to distances 1, 2, 4, 8, and so on, returning to the origin after each unsuccessful exploration. The first leg is toward the negative side.

## Contract

The `i64_array_bytes_output` input contains one signed target coordinate `x`, with `1 <= |x| <= 50,000`. The distance lower bound is the source model’s condition that the hidden target is at least one unit from the origin. On leg `i`, the search direction is negative for even `i` and positive for odd `i`; the endpoint distance is `2^i`. If the target is on that ray and its magnitude is no greater than the endpoint, it is discovered on the outward traversal. Otherwise the leg is completed and the searcher returns to the origin.

Output is `[total_distance_traveled, zero_based_leg_index]` as two little-endian signed-i64 values. Total cost includes every failed leg’s outward and return travel, then the final outward distance to the target. The function returns 16, `-1` for malformed or out-of-range input, and `-2` for a null or short output buffer. The input is validated before capacity checks and output is not written on failure.

This profile measures the no-information deterministic line-search strategy, not the chapter’s known-distance variant, randomized strategies, or multi-ray/star search.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/deterministic_line_search.c`](../../../c/deterministic_line_search.c) |
| C3 | [`c3/d/deterministic_line_search.c3`](../../../c3/d/deterministic_line_search.c3) |
| C++ | [`cpp/d/deterministic_line_search.cpp`](../../../cpp/d/deterministic_line_search.cpp) |
| Elisa | [`elisa/d/deterministic_line_search.elisa`](../../../elisa/d/deterministic_line_search.elisa) |
| Nim | [`nim/d/deterministic_line_search.nim`](../../../nim/d/deterministic_line_search.nim) |
| Odin | [`odin/d/deterministic_line_search.odin`](../../../odin/d/deterministic_line_search.odin) |
| Rust | [`rust/d/deterministic_line_search.rs`](../../../rust/d/deterministic_line_search.rs) |
| V | [`v/d/deterministic_line_search.v`](../../../v/d/deterministic_line_search.v) |
| Zig | [`zig/d/deterministic_line_search.zig`](../../../zig/d/deterministic_line_search.zig) |

The primary oracle is [`deterministic_line_search_oracle.py`](../../deterministic_line_search_oracle.py); the independent verifier uses the closed-form failed-leg distance sum in [`deterministic_line_search_verifier_oracle.py`](../../deterministic_line_search_verifier_oracle.py).

## Attribution and rights

The strategy is attributed to Spyros Angelopoulos, “Deterministic Searching on the Line,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_106. The Springer chapter is used only to identify the strategy and model; no book prose, figures, or code are reproduced. All package code is independently written. This attribution does not grant rights to redistribute the book.
