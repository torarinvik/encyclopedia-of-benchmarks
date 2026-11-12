# Finite discrete rejection sampling

This package samples categories from a finite integer-weight target using a
separate finite integer-weight proposal, an automatically computed envelope,
and a supplied deterministic draw tape. The profile exposes the proposal and
acceptance work on each attempt so it can be compared across implementations
without invoking a random-number generator.

## Contract

The byte-output ABI symbol is `discrete_rejection_sampling`. Its input is
`[category_count, samples_wanted, attempt_cap, target_weights..., proposal_weights...,
(proposal_draw, acceptance_draw)*attempt_cap]`. There are 1–8 categories,
1–8 requested samples, and 1–32 attempts. Every target and proposal weight is
in `1..=20`. Let `W` and `Q` be their respective sums.

For category `i`, the target probability is `w_i/W` and proposal probability
is `q_i/Q`. The ports choose the integer envelope
`M = max_i ceil(w_i*Q/(W*q_i))`, so `M*q_i/Q >= w_i/W` for every category.
Each proposal draw is an integer in `[0,Q)`. Cumulative proposal weights
select the first category whose cumulative total is greater than the draw. An
acceptance draw `u` is in `[0,2^32)` and represents the exact grid point
`u/2^32`; category `i` is accepted iff
`u * W * q_i * M < 2^32 * w_i * Q`. These integer comparisons avoid floating
point and leave the draw-tape behavior identical across ports. As with any
finite supplied tape, the benchmark measures a deterministic trace rather than
making a statistical quality claim.

Each attempt consumes one proposal and one acceptance draw. On acceptance,
the output records `(category_index, attempts_since_previous_acceptance)`.
Unused tape suffixes are ignored. If the tape reaches its cap before all
requested samples are accepted, the function returns `-3` and writes nothing.
Malformed frames, weights, or draws return `-1`. Null output or capacity below
`16*samples_wanted` returns `-2`, without writes. A successful call returns
that byte count and writes signed 64-bit little-endian values. The maximum
input has 83 integers, maximum output is 128 bytes, and workspace is 4,096
bytes. Time is `O(category_count * attempt_cap)`; working storage is
`O(category_count + samples_wanted)`.

## Distinction and verification

The local [`marsaglia_polar_normal`](../marsaglia_polar_normal/README.md)
benchmark uses a fixed two-dimensional proposal, a unit-circle acceptance
condition, and a Gaussian transform. [`weighted_random_sampling`](../../w/weighted_random_sampling/README.md)
selects a weighted subset by ordering rational random-priority keys. This
package instead accepts caller-supplied finite target and proposal weights,
computes an envelope, and emits a bounded sequence of accepted categories.

The [primary oracle](primary_oracle.py) replays integer draw pairs and uses
cross multiplication for acceptance. The [independent oracle](independent_oracle.py)
constructs exact rational acceptance thresholds and uses a cumulative table
with binary search. The [workload](workload.json) covers direct acceptance,
rejection followed by acceptance, proposal bounds, malformed input, exhausted
tape, output capacity, and the maximum profile.

## Provenance and rights

The Algorithm Archive includes a chapter on rejection-sampling cost. Its
general accept/reject construction is specified here from Luc Devroye,
[*Non-Uniform Random Variate Generation*](https://doi.org/10.1007/978-1-4613-8643-8_2),
Chapter II, section 3 (1986). The Archive page is
[here](https://www.algorithm-archive.org/contents/box_muller/box_muller_rejection.html).
See [`RIGHTS.md`](RIGHTS.md). These ports use algorithm descriptions only and
contain independently written code.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/discrete_rejection_sampling.c`](../../../c/d/discrete_rejection_sampling.c) |
| C3 | [`c3/d/discrete_rejection_sampling.c3`](../../../c3/d/discrete_rejection_sampling.c3) |
| C++ | [`cpp/d/discrete_rejection_sampling.cpp`](../../../cpp/d/discrete_rejection_sampling.cpp) |
| Elisa | [`elisa/d/discrete_rejection_sampling.elisa`](../../../elisa/d/discrete_rejection_sampling.elisa) |
| Mojo | [`mojo/d/discrete_rejection_sampling.mojo`](../../../mojo/d/discrete_rejection_sampling.mojo) |
| Nim | [`nim/d/discrete_rejection_sampling.nim`](../../../nim/d/discrete_rejection_sampling.nim) |
| Odin | [`odin/d/discrete_rejection_sampling.odin`](../../../odin/d/discrete_rejection_sampling.odin) |
| Rust | [`rust/d/discrete_rejection_sampling.rs`](../../../rust/d/discrete_rejection_sampling.rs) |
| V | [`v/d/discrete_rejection_sampling.v`](../../../v/d/discrete_rejection_sampling.v) |
| Zig | [`zig/d/discrete_rejection_sampling.zig`](../../../zig/d/discrete_rejection_sampling.zig) |
