# Independent Bernoulli randomized rounding

This profile implements the basic rounding rule in “Randomized Rounding,” DOI
[`10.1007/978-1-4939-2864-4_327`](https://doi.org/10.1007/978-1-4939-2864-4_327):
given fractional LP values `x_i`, select each variable independently with
probability `x_i`.

The LP solution and random draws are inputs. To make the benchmark replayable,
each draw is supplied as an exact rational `u_i` in `[0,1)`. The output bit is
one exactly when `u_i < x_i`; this is a deterministic projection of one
independent-uniform draw tape and does not claim a probabilistic property for a
particular fixture.

Input is `[n,(x_num,x_den,u_num,u_den)...]` with `1 <= n <= 16`,
`0 <= x_num <= x_den <= 32`, and `0 <= u_num < u_den <= 32`. The maximum input
length is 65 signed 64-bit integers. Output is one byte (`0` or `1`) per input
variable, for at most 16 bytes. Invalid input returns `-1`; null output or
insufficient capacity returns `-2` without writing.

The profile covers the chapter's basic independent Bernoulli rule. It does not
solve the LP or claim the approximation guarantees of any of the chapter's
VLSI-routing, congestion, or hypergraph-matching applications. It is distinct
from `weighted_random_sampling`, which orders Efraimidis–Spirakis weighted
keys to select a fixed-size sample, and from `max_cut_gw_rounding`, which uses
random hyperplane signs.

| Language | Port |
|---|---|
| C | `c/r/randomized_rounding_bernoulli.c` |
| C3 | `c3/r/randomized_rounding_bernoulli.c3` |
| C++ | `cpp/r/randomized_rounding_bernoulli.cpp` |
| Elisa | `elisa/r/randomized_rounding_bernoulli.elisa` |
| Nim | `nim/r/randomized_rounding_bernoulli.nim` |
| Odin | `odin/r/randomized_rounding_bernoulli.odin` |
| Rust | `rust/r/randomized_rounding_bernoulli.rs` |
| V | `v/r/randomized_rounding_bernoulli.v` |
| Zig | `zig/r/randomized_rounding_bernoulli.zig` |
