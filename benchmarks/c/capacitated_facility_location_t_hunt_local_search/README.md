# Capacitated facility-location T-Hunt local search

This package benchmarks a bounded outer local-search profile for capacitated
facility location. It combines the source's generic strict-improvement loop
and single-copy-add neighborhood with the one-target T-Hunt selector in
[`capacitated_facility_location_t_hunt`](../capacitated_facility_location_t_hunt/README.md).
It is distinct from that selector, which evaluates only one supplied state
and one target type, and from uncapacitated
[`facility_location_add_delete_swap`](../../f/facility_location_add_delete_swap/README.md).

## Deterministic profile

The input supplies an initial multiset of facility copies. The profile first
computes a minimum-cost feasible assignment. It breaks assignment ties by the
lexicographically smallest vector of facility type IDs, then packs clients in
ascending ID order into the earliest available copies of their assigned type.
Copies are represented in nondecreasing facility-type order.

Each pass scans target types in ascending ID. For each target, it first checks
the source's one-copy-add move, including a fresh minimum-cost assignment. If
that does not strictly improve the objective, it runs T-Hunt for that target:
scan `l=1..n`, solve the profit knapsack over current copies with capacity
`l*capacity[target]`, and return the first subset whose profit strictly
exceeds `l*opening_fee[target]`. The knapsack uses exact assigned-client counts
as weights and the source profit formula. Equal exact-weight DP states keep
the path that skips the latest copy; equal final profits choose the smaller
used weight. A selected T-Hunt move removes those copies and adds `l` target
copies. The assignment is then recomputed optimally.

The first improving move found is applied and scanning restarts at target 0.
The process stops after a full pass finds no improving one-copy-add or
T-Hunt move. The paper leaves initial solutions, improving-neighbor choice,
and ties arbitrary; the scan and tie rules above make this benchmark profile
reproducible. The stopping condition means the fixed T-Hunt scan found no
improving move; it does not certify that no other neighbor in the full
mathematical neighborhood improves.

## Complexity

Let `C` be the current copy count (`C<=644`) and `S` the number of accepted
moves (`S<=160`). A minimum-cost assignment enumerates at most `F^n` facility
type vectors and then packs the chosen assignment into the copies, taking
`O(F^n*n + C + n)` time. Each T-Hunt knapsack call takes `O(C*n)` time and
stores `O(C*n)` choice flags; each candidate accepted by the scan is followed
by another minimum-cost assignment. Across the at most `S` improving passes
and one final failed pass, the bounded profile takes
`O(F^n*n + (S+1)*F*(n+1)*(C*n + F^n*n + C))` time and
`O((n+F)^2 + C*n + C + n)` auxiliary space. The fixed limits `F<=3` and
`n<=4` keep the assignment enumeration bounded.

## Contract

ABI: `i64_array_bytes_output`; symbol:
`capacitated_facility_location_t_hunt_local_search`.
Input is
`[n,F,Q,D[(n+F)^2 row-major],opening_fee[F],capacity[F],copy_type[Q]]`.

- `1<=n<=4`, `1<=F<=3`, and `1<=Q<=4` initially.
- The distance matrix is a symmetric integer metric on the `n` clients and
  `F` facility types, with zero diagonal, positive off-diagonal distances, and
  entries in `0..20`.
- Opening fees are in `0..20`; capacities are in `1..n`; each copy type is in
  `0..F-1`; the initial copies' total capacity must cover all clients.
- Maximum valid input is 62 words; maximum parseable input is 63 words.
  Null or malformed input returns `-1`.

Output is a little-endian signed-i64 vector
`[final_cost,accepted_steps,copy_count,copy_type[copy_count],assignment[n]]`.
The final copy list is sorted by type, and each assignment entry is the copy
ID serving that client. The initial objective is at most 160. Since costs are
integers and every accepted move strictly lowers cost, there are at most 160
accepted moves. Each move adds at most `n` copies, so the final copy count is
at most 644 and output capacity at most 5,208 bytes. Null output or
insufficient capacity returns `-2` without writes.

The primary reference uses exact-weight knapsack DP for each T-Hunt call. The
independent reference enumerates weight-class choices to maximize knapsack
profit, while both recompute the minimum-cost assignment by direct enumeration
of the at most `F^n` type assignments. The workload includes a single-copy
addition, a multi-copy drop/add move, a no-improvement maximum input, invalid
capacity, trailing input, and null/capacity ABI cases.

## Sources and rights

The book source is Kamesh Munagala, “Local Search for K-medians and Facility
Location,” [Encyclopedia of Algorithms entry 212](https://doi.org/10.1007/978-1-4939-2864-4_212).
The primary algorithm is Arya, Garg, Khandekar, Meyerson, Munagala, and Pandit,
“Local Search Heuristics for k-Median and Facility Location Problems,”
*SIAM Journal on Computing* 33(3), [DOI
10.1137/S0097539702416402](https://doi.org/10.1137/S0097539702416402), §2,
Figure 1, and §5.1, Eq. (9), Figure 13. The bounded metric, deterministic
tie rules, copy scan, and output trace are profile choices. All ports and
references are clean-room implementations from algorithm descriptions; no
source code or prose was copied. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/capacitated_facility_location_t_hunt_local_search.c`](../../../c/c/capacitated_facility_location_t_hunt_local_search.c) |
| C3 | [`c3/capacitated_facility_location_t_hunt_local_search.c3`](../../../c3/c/capacitated_facility_location_t_hunt_local_search.c3) |
| C++ | [`cpp/capacitated_facility_location_t_hunt_local_search.cpp`](../../../cpp/c/capacitated_facility_location_t_hunt_local_search.cpp) |
| Elisa | [`elisa/capacitated_facility_location_t_hunt_local_search.elisa`](../../../elisa/c/capacitated_facility_location_t_hunt_local_search.elisa) |
| Mojo | [`mojo/capacitated_facility_location_t_hunt_local_search.mojo`](../../../mojo/c/capacitated_facility_location_t_hunt_local_search.mojo) |
| Nim | [`nim/capacitated_facility_location_t_hunt_local_search.nim`](../../../nim/c/capacitated_facility_location_t_hunt_local_search.nim) |
| Odin | [`odin/capacitated_facility_location_t_hunt_local_search.odin`](../../../odin/c/capacitated_facility_location_t_hunt_local_search.odin) |
| Rust | [`rust/capacitated_facility_location_t_hunt_local_search.rs`](../../../rust/c/capacitated_facility_location_t_hunt_local_search.rs) |
| V | [`v/capacitated_facility_location_t_hunt_local_search.v`](../../../v/c/capacitated_facility_location_t_hunt_local_search.v) |
| Zig | [`zig/capacitated_facility_location_t_hunt_local_search.zig`](../../../zig/c/capacitated_facility_location_t_hunt_local_search.zig) |

See [workload.json](workload.json), [primary oracle](primary_oracle.py),
[independent oracle](independent_oracle.py), and the static
[package inventory](verify_workload.py).
