# Randomized add-one/delete-many facility location

This package benchmarks the Charikar–Guha randomized local-search update for
uncapacitated facility location described in Encyclopedia of Algorithms entry
212. It differs from [`facility_location_add_delete_swap`](../facility_location_add_delete_swap/README.md),
which considers one-copy additions, deletions, and swaps. Here a sampled new
facility can take clients from several open facilities, allowing all of those
facilities to be deleted in one accepted step. It is also separate from the
capacitated T-Hunt package, which uses a knapsack move selector.

## Bounded profile

The supplied tape contains `Q` facility IDs chosen by the randomized source
procedure. Replaying the tape makes each call deterministic and comparable
across language ports; the package does not claim a probabilistic guarantee or
generate random choices internally. Draws are over all facility IDs. A draw
whose facility is already open is a no-op, as in the source algorithm's
zero-gain treatment of an already-open choice.

For a closed candidate `i`, mark every client `j` for which the distance from
`j` to `i` is strictly smaller than its current assigned distance. Those
clients move to `i`. For each currently open facility `s`, consider its
assigned clients that were not already marked. Delete `s` and move those
remaining clients to `i` exactly when
`fee[s] + current_service_cost > candidate_service_cost` for that group.
These per-facility decisions are independent. Add `i` and apply all selected
deletions only when the combined objective strictly decreases. Assignments
not moved by this step stay at their supplied center; the procedure does not
re-optimize all assignments after a move. Distance ties do not enter the
strictly-closer client set, and zero-saving facility deletions are not chosen.

## ABI and input

ABI: `i64_array_bytes_output`; symbol: `facility_location_randomized_add_delete_many`.
Input is
`[n,F,Q,initial_mask,assignment[n],demand[n],D[(n+F)^2 row-major],fee[F],draw[Q]]`.
Clients use IDs `0..n-1`; facilities use IDs `0..F-1` and occupy metric
indices `n..n+F-1`.

- `1<=n,F<=5`, `1<=Q<=8`, and the initial mask is nonempty.
- Every initial client assignment names an open facility. The assignment is
  feasible by definition because this is the uncapacitated variant; it need
  not be nearest.
- Demands are integers in `1..10`; facility opening fees are integers in
  `0..1000`.
- `D` is a symmetric metric on the distinct client and facility points, with
  zero diagonal, positive off-diagonal distances, and integer entries in
  `0..1000`.
- Each tape entry is a facility ID in `0..F-1`. In the source algorithm, each
  entry is sampled uniformly from the facility candidates; workload tapes
  are fixed deterministic draws.
- Maximum valid input is 127 words; maximum parseable input is 128 words.
  Malformed or null input returns `-1`.

The little-endian signed-i64 output is
`[cost_after[Q],accepted[Q],final_cost,final_open_mask,final_assignment[n],accepted_count]`.
It uses `8*(2*Q+3+n)` bytes, at most 192. Null output or insufficient
capacity returns `-2` without writing.

The primary reference performs the source's W-set and per-facility gain scan.
The independent reference enumerates all subsets of currently open facilities
for each draw and chooses the minimum-cost admissible result. Workloads include
hand-derived accepted, rejected, strict-tie, multi-delete, already-open, and
maximum-size traces.

## Complexity

Metric validation takes `O((n+F)^3)` time. Each replayed draw scans clients and
open facilities, taking `O(F*n)` time; the complete profile therefore takes
`O((n+F)^3 + Q*F*n)` time and `O((n+F)^2 + Q + n + F)` auxiliary space. The
independent subset-enumeration reference is deliberately slower, taking
`O(Q*(2^F)*(n+F))` time within the small `F<=5` bound.

## Sources and rights

The book source is Kamesh Munagala, “Local Search for K-medians and Facility
Location,” [Encyclopedia of Algorithms, entry 212](https://doi.org/10.1007/978-1-4939-2864-4_212),
Facility Location section. The algorithm reference is Moses Charikar and
Sudipto Guha, “Improved Combinatorial Algorithms for Facility Location
Problems,” *SIAM Journal on Computing* 34(4), [DOI
10.1137/S0097539701398594](https://doi.org/10.1137/S0097539701398594), §2.
The book chapter identifies the add-one/delete-many move and its W/I(i)
construction; the paper specifies the random-candidate loop and accepts only
positive-gain updates. The benchmark's supplied initial assignment and draw
tape, integer bounds, and fixed trace output are profile choices. All ports
and references are clean-room implementations from algorithm descriptions;
no source code or prose was copied. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/f/facility_location_randomized_add_delete_many.c`](../../../c/f/facility_location_randomized_add_delete_many.c) |
| C3 | [`c3/f/facility_location_randomized_add_delete_many.c3`](../../../c3/f/facility_location_randomized_add_delete_many.c3) |
| C++ | [`cpp/f/facility_location_randomized_add_delete_many.cpp`](../../../cpp/f/facility_location_randomized_add_delete_many.cpp) |
| Elisa | [`elisa/f/facility_location_randomized_add_delete_many.elisa`](../../../elisa/f/facility_location_randomized_add_delete_many.elisa) |
| Mojo | [`mojo/f/facility_location_randomized_add_delete_many.mojo`](../../../mojo/f/facility_location_randomized_add_delete_many.mojo) |
| Nim | [`nim/f/facility_location_randomized_add_delete_many.nim`](../../../nim/f/facility_location_randomized_add_delete_many.nim) |
| Odin | [`odin/f/facility_location_randomized_add_delete_many.odin`](../../../odin/f/facility_location_randomized_add_delete_many.odin) |
| Rust | [`rust/f/facility_location_randomized_add_delete_many.rs`](../../../rust/f/facility_location_randomized_add_delete_many.rs) |
| V | [`v/f/facility_location_randomized_add_delete_many.v`](../../../v/f/facility_location_randomized_add_delete_many.v) |
| Zig | [`zig/f/facility_location_randomized_add_delete_many.zig`](../../../zig/f/facility_location_randomized_add_delete_many.zig) |

See [workload.json](workload.json), the [primary oracle](primary_oracle.py),
the [independent oracle](independent_oracle.py), and the static
[package inventory](verify_workload.py).
