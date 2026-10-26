# Randomized search on rays with supplied randomness

This package simulates the chapter's `RaySearch` strategy for one supplied
random sample. The sample consists of a ray permutation and a starting
distance `d0`; the source's random initial value `r^epsilon` ranges over
`[1,r)`, so any `d0` in that interval corresponds to a valid epsilon. The
profile uses integer growth factors `2..4` and fixed-point distance ticks
(`1000` ticks per distance unit), making all nine ports use identical exact
integer arithmetic. It does not generate the random permutation, sample
epsilon, or compute the optimal real-valued growth factor.

Input is `[ray_count, growth_factor, initial_distance_ticks,
permutation..., target_ray, target_distance_ticks]`. The searcher visits rays
in the supplied fixed order cyclically, explores the current distance, returns
to the origin after a miss, and multiplies the distance by the growth factor.
The first trip that crosses the target ends the search. Output is
`[exploration_count, total_distance_ticks]`; each missed trip costs twice its
exploration distance, and the successful trip costs the target distance.

There are 2 through 5 rays, growth factor 2 through 4, starting distance in
`[1,r)` in fixed-point units, and target distance from 1 through 1,000,000,000
ticks. The valid sample always finds the target within 25 explorations.
Malformed permutations or framing return `-1`; null output or capacity below
16 bytes returns `-2` without writing. Maximum valid input is 10 values and
maximum parseable length is 11.

The primary oracle simulates each trip. The independent verifier computes the
first growth round that reaches the target and sums the missed round-trip
distances as a geometric series.

Source: Stephen R. Tate, “Randomized Searching on Rays or the Line,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_328`](https://doi.org/10.1007/978-1-4939-2864-4_328).
This is a deterministic execution profile for a supplied valid sample from
the chapter's randomized strategy, not a random-number generator. See
[`RIGHTS.md`](RIGHTS.md) for provenance.

## Workload and ports

The [workload](workload.json) covers an early hit, cyclic return and growth,
maximum ray/target bounds, malformed samples, null buffers, and insufficient
capacity.

| Language | Port |
| --- | --- |
| C | [`c/r/randomized_ray_search.c`](../../../c/r/randomized_ray_search.c) |
| C3 | [`c3/r/randomized_ray_search.c3`](../../../c3/r/randomized_ray_search.c3) |
| C++ | [`cpp/r/randomized_ray_search.cpp`](../../../cpp/r/randomized_ray_search.cpp) |
| Elisa | [`elisa/r/randomized_ray_search.elisa`](../../../elisa/r/randomized_ray_search.elisa) |
| Nim | [`nim/r/randomized_ray_search.nim`](../../../nim/r/randomized_ray_search.nim) |
| Odin | [`odin/r/randomized_ray_search.odin`](../../../odin/r/randomized_ray_search.odin) |
| Rust | [`rust/r/randomized_ray_search.rs`](../../../rust/r/randomized_ray_search.rs) |
| V | [`v/r/randomized_ray_search.v`](../../../v/r/randomized_ray_search.v) |
| Zig | [`zig/r/randomized_ray_search.zig`](../../../zig/r/randomized_ray_search.zig) |
