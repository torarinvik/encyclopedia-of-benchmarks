# Capacitated facility-location T-Hunt

This package benchmarks the T-Hunt neighborhood procedure from §5.1 and
Figure 13 of the capacitated facility-location section of Encyclopedia of
Algorithms entry 212. It is distinct from
[`facility_location_add_delete_swap`](../../f/facility_location_add_delete_swap/README.md):
that package is uncapacitated and searches one-copy add, delete, and swap
moves; T-Hunt uses capacities, opens `l` copies of one target type, and chooses
a subset of current facility copies to drop by solving a profit knapsack.

## Bounded profile

The call supplies one feasible capacitated state, the current client-to-copy
assignment, and one target facility type. The implementation scans
`l = 1, ..., n` in ascending order. For each `l`, it maximizes profit over
subsets of current facility copies with total assigned-client weight at most
`l * target_capacity`. A selected copy has weight equal to its assigned-client
count and profit equal to its opening cost minus the clients' total increase in
distance if they move to the target. The first subset whose profit exceeds
`l * target_opening_cost` is returned. Equal-profit subsets use the numerically
smallest copy bitmask.

This is the source's T-Hunt move selector on a bounded integer metric. The
profile supplies one state and one target, so it measures neither the outer
local-search loop nor convergence to a local optimum. The source permits
arbitrary candidate metrics satisfying its stated metric model; here the
supplied full matrix is validated exactly. The deterministic mask tie rule and
bounded dimensions are profile choices. The supplied assignment is feasible
but need not be recomputed by a minimum-cost assignment solver.

## ABI and input

ABI: `i64_array_bytes_output`; symbol: `capacitated_facility_location_t_hunt`.
Input is
`[n,F,Q,target, D[(n+F)^2 row-major], opening_cost[F], capacity[F], copy_type[Q], assignment[n]]`.
Client IDs are `0..n-1`; facility-type IDs are `0..F-1`; current copy IDs are
`0..Q-1`. Each assignment gives the current copy serving that client.

- `1 <= n <= 4`, `1 <= F <= 3`, `1 <= Q <= 4`, and `0 <= target < F`.
- `D` is a symmetric metric with zero diagonal, positive off-diagonal values,
  and integer distances in `0..1000`.
- Opening costs are in `0..1000`; capacities are in `1..n`.
- Each current copy has a valid facility type, and its assigned client count
  does not exceed that type's capacity.
- Maximum valid input is 67 words; one extra parseable word is reserved for
  trailing-frame rejection.

The fixed output is five little-endian signed 64-bit words:
`[improved, l, dropped_copy_mask, current_cost, modeled_neighbor_cost]`.
`improved` is 1 for the first improving T-Hunt move and 0 if none is found.
The modeled neighbor cost adds `l` target opening fees and moves only clients
assigned to dropped copies; all other supplied assignments remain unchanged.
The output is 40 bytes. Invalid input returns `-1`; null or short output returns
`-2` without writes.

Primary reference uses exact-weight dynamic programming for the profit
knapsack. The independent reference enumerates every dropped-copy subset
directly. Both use the same explicitly bounded deterministic profile, with
independent selection procedures.

## Provenance and rights

The book entry is Kamesh Munagala, “Local Search for K-medians and Facility
Location,” [Encyclopedia of Algorithms, DOI
10.1007/978-1-4939-2864-4_212](https://doi.org/10.1007/978-1-4939-2864-4_212).
The cited method is described in Arya, Garg, Khandekar, Meyerson, Munagala,
and Pandit, “Local Search Heuristics for k-Median and Facility Location
Problems,” *SIAM Journal on Computing* 33(3), [DOI
10.1137/S0097539702416402](https://doi.org/10.1137/S0097539702416402).
The ports and references are clean-room implementations of the algorithm
description; no source code or chapter prose is copied. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/capacitated_facility_location_t_hunt.c`](../../../c/c/capacitated_facility_location_t_hunt.c) |
| C3 | [`c3/capacitated_facility_location_t_hunt.c3`](../../../c3/c/capacitated_facility_location_t_hunt.c3) |
| C++ | [`cpp/capacitated_facility_location_t_hunt.cpp`](../../../cpp/c/capacitated_facility_location_t_hunt.cpp) |
| Elisa | [`elisa/capacitated_facility_location_t_hunt.elisa`](../../../elisa/c/capacitated_facility_location_t_hunt.elisa) |
| Mojo | [`mojo/capacitated_facility_location_t_hunt.mojo`](../../../mojo/c/capacitated_facility_location_t_hunt.mojo) |
| Nim | [`nim/capacitated_facility_location_t_hunt.nim`](../../../nim/c/capacitated_facility_location_t_hunt.nim) |
| Odin | [`odin/capacitated_facility_location_t_hunt.odin`](../../../odin/c/capacitated_facility_location_t_hunt.odin) |
| Rust | [`rust/capacitated_facility_location_t_hunt.rs`](../../../rust/c/capacitated_facility_location_t_hunt.rs) |
| V | [`v/capacitated_facility_location_t_hunt.v`](../../../v/c/capacitated_facility_location_t_hunt.v) |
| Zig | [`zig/capacitated_facility_location_t_hunt.zig`](../../../zig/c/capacitated_facility_location_t_hunt.zig) |

See [workload.json](workload.json), [primary oracle](primary_oracle.py), and
[independent oracle](independent_oracle.py).
