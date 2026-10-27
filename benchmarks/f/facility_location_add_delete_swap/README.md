# Facility-location add/delete/swap local search

This profile implements the Kuehn–Hamburger add/delete/swap neighborhood
described in Chapter 212. The input supplies a feasible nonempty facility set
and a finite metric on demand points and candidate facility locations. Each
facility has an opening cost. The objective is the sum of each demand point's
distance to its nearest open facility plus the opening costs of the open
facilities.

At every iteration, the profile evaluates every legal one-facility addition,
one-facility deletion, and one-for-one swap. It takes the lowest-cost
strictly improving neighbor; equal objective values among improving neighbors
use the lexicographically smallest sorted facility list. The profile fixes
the chapter's generic stopping parameter to `epsilon=0.1` and stops when the
best neighbor has cost at least 90% of the current cost. The output includes
the local solution and each demand point's nearest open facility.

## Contract

ABI: `i64_array_bytes_output`; symbol: `facility_location_add_delete_swap`.
Input is `[n,m,D[(n+m)×(n+m)] row-major, opening_cost[m], initial_facility_mask]`.
IDs `0..n-1` identify demand points and IDs `n..n+m-1` identify candidate
facilities in the supplied metric matrix; output facility IDs are local
`0..m-1` IDs.

- `1<=n,m<=7` and `n+m<=8`; the matrix is a symmetric metric with zero
  diagonal and integer distances in `[0,1000]` (strictly positive off-diagonal).
- Opening costs are integers in `[0,1000]`; the initial mask must select at
  least one in-range facility.
- Output is `[objective,facility_count,sorted_facility_ids[k],assigned_facility_id_per_demand[n]]`
  (the center list contains `facility_count` words) as little-endian signed
  i64. An assignment is the nearest open facility; ties choose lower ID.
  Maximum input is 74 words and output is 80 bytes.
- Invalid framing or metric data returns `-1`. Null output or short capacity
  returns `-2` without writes.

This is uncapacitated facility location with opening costs; it is distinct
from the repository's fixed-k p=1 k-median profile, which has no opening-cost
term and only swaps centers. The profile covers the deterministic
add/delete/swap procedure and a fixed 0.1 stopping threshold; it does not
implement the randomized add-one/delete-many heuristic or capacitated local
search variants and makes no independent approximation-ratio claim.

Source: Kamesh Munagala, “Local Search for K-medians and Facility Location,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_212`](https://doi.org/10.1007/978-1-4939-2864-4_212),
Facility Location section. The chapter gives no explicit source-code license;
ports and oracles are clean-room implementations of the described moves and
objective. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | `c/f/facility_location_add_delete_swap.c` |
| C3 | `c3/f/facility_location_add_delete_swap.c3` |
| C++ | `cpp/f/facility_location_add_delete_swap.cpp` |
| Elisa | `elisa/f/facility_location_add_delete_swap.elisa` |
| Nim | `nim/f/facility_location_add_delete_swap.nim` |
| Odin | `odin/f/facility_location_add_delete_swap.odin` |
| Rust | `rust/f/facility_location_add_delete_swap.rs` |
| V | `v/f/facility_location_add_delete_swap.v` |
| Zig | `zig/f/facility_location_add_delete_swap.zig` |

See [workload.json](workload.json), [primary oracle](../../facility_location_add_delete_swap_oracle.py),
and [independent verifier](../../facility_location_add_delete_swap_verifier_oracle.py).
