# Random 3-SAT CL bucket heuristic

This package implements a bounded deterministic replay of Kaporis, Kirousis,
and Lalas's CL heuristic. At each free step it groups unset literals by the
capped occurrence degrees of the literal and its complement (`h=10`). It
simulates one free assignment followed by unit propagation for the lowest-ID
literal in every nonempty bucket, computes the change in the source's `m2`
and `m3` literal-occurrence flows, and chooses the bucket with maximum
`(m2'−m2)/(m3'−m3)`. A chosen bucket is replayed with the same lowest-ID rule.
Unit clauses are propagated first and after every free assignment.

## Contract

ABI: `i64_array_bytes_output`; symbol `random_3sat_cl_bucket_heuristic`.
Input is `[n,m,(k,l1,l2,l3)*m]`, with `1<=n<=8`, `0<=m<=24`, and each
clause size `k` in `1..3`. Literals are signed one-based variable IDs. The
first `k` literal slots must be nonzero, in range, and use distinct variables;
remaining slots must be zero. Repeated clauses are allowed. The maximum valid
frame is 98 words; a 99-word frame is parseable for trailing-word rejection.
Literal magnitude conversion follows an explicit signed range check, including
the signed-i64 minimum malformed-literal fixture.

For a residual formula, let `d_k(l)` count occurrences of literal `l` in
exactly `k`-clauses. The source flow rates are
`m2 = average_{l occurrence in a 2-clause} d_2(-l)` and
`m3 = average_{l occurrence in a 2-clause} d_3(-l)`. If there are no 2-clause
occurrences, both rates are defined as zero for this finite profile. For each
bucket trial, the rational score is compared exactly; a trial that creates an
empty clause or has `m3'−m3 = 0` is ineligible. The maximizing pair is selected
with lowest `(i,j)` ties. If no bucket has an eligible score, the trace stops
with status 2. This makes the finite-input boundary explicit where the paper's
ratio is undefined.

The output is little-endian signed-i64 words:
`[status,n,assigned_count,assignment[n],trace_count,(literal,kind,bucket_i,bucket_j)*trace_count]`.
Status 0 means every variable received a value without contradiction; status
1 means the replay generated an empty clause; status 2 means the bucket score
was undefined for every candidate. Status 1 is only failure of this
no-backtrack replay, not a proof that the formula is unsatisfiable. Assignment
entries are `1` for true, `-1` for false, and `0` while unset. Trace kind 0 is
a free-step choice and carries its bucket indices; kind 1 is a forced unit
choice and carries `(-1,-1)`. Each residual clause contains only unset
variables, so every logged event consumes a distinct variable; even a terminal
contradiction cannot produce more than `n` events. Success writes up to 352 bytes. Invalid frames
return `-1`; null output or insufficient capacity returns `-2` without writing.

The fixed implementation limit is 16,384 bytes of workspace. Formula
simplification and each flow recomputation scan at most `m` clauses and `n`
variables. There are at most 121 bucket trials at each of at most `n` free
steps, with at most `n` unit assignments in each trial, giving the safe bound
`O(121*n^2*(m+n))` time and `O(m+n)` working words for the stated bounds.

## Provenance and distinction

The operational procedure is Algorithm CL and Definitions 1–2 in Kaporis,
Kirousis, and Lalas, “Selecting Complementary Pairs of Literals,” *Electronic
Notes in Discrete Mathematics* 16 (2003), 47–70,
[DOI 10.1016/S1571-0653(04)00462-7](https://doi.org/10.1016/S1571-0653(04)00462-7).
The exact interpretation of `m2` and `m3` as literal-occurrence flows is also
given in §5 of “The Probabilistic Analysis of a Greedy Satisfiability
Algorithm,” *Random Structures & Algorithms* 28(4) (2006), 444–480,
[DOI 10.1002/rsa.20104](https://doi.org/10.1002/rsa.20104). Chapter 423 of the
*Encyclopedia of Algorithms* provides context for random k-SAT. The local
`random_3sat_greedy_dpll` profile uses unit-first no-backtrack propagation;
`random_3sat_hajiaghayi_sorkin_algorithm_a` uses a direct variable degree-pair
rule. CL's per-bucket simulated flow scoring is a separate selection
procedure. This package supplies the formula and uses deterministic lowest-ID
choices, so it measures neither random behavior nor the paper's threshold or
success-probability guarantees.

All implementations are clean-room translations of the mathematical method.
No source code, prose, examples, tests, or submissions are copied.

## Package files

The two references are `primary_oracle.py` (mutable residual clauses) and
`independent_oracle.py` (immutable tuple formulas and independently rebuilt
degree counters). `workload.json` pins bounded traces and ABI errors.
`check_inventory.py` statically lists the package artifacts and language
ports; `verify_workload.py` reconciles pinned fixture bytes against both
references. Both helpers are provided for integration and were not run.

| Language | Source |
|---|---|
| C | [`c/r/random_3sat_cl_bucket_heuristic.c`](../../../c/r/random_3sat_cl_bucket_heuristic.c) |
| C3 | [`c3/r/random_3sat_cl_bucket_heuristic.c3`](../../../c3/r/random_3sat_cl_bucket_heuristic.c3) |
| C++ | [`cpp/r/random_3sat_cl_bucket_heuristic.cpp`](../../../cpp/r/random_3sat_cl_bucket_heuristic.cpp) |
| Elisa | [`elisa/r/random_3sat_cl_bucket_heuristic.elisa`](../../../elisa/r/random_3sat_cl_bucket_heuristic.elisa) |
| Mojo | [`mojo/r/random_3sat_cl_bucket_heuristic.mojo`](../../../mojo/r/random_3sat_cl_bucket_heuristic.mojo) |
| Nim | [`nim/r/random_3sat_cl_bucket_heuristic.nim`](../../../nim/r/random_3sat_cl_bucket_heuristic.nim) |
| Odin | [`odin/r/random_3sat_cl_bucket_heuristic.odin`](../../../odin/r/random_3sat_cl_bucket_heuristic.odin) |
| Rust | [`rust/r/random_3sat_cl_bucket_heuristic.rs`](../../../rust/r/random_3sat_cl_bucket_heuristic.rs) |
| V | [`v/r/random_3sat_cl_bucket_heuristic.v`](../../../v/r/random_3sat_cl_bucket_heuristic.v) |
| Zig | [`zig/r/random_3sat_cl_bucket_heuristic.zig`](../../../zig/r/random_3sat_cl_bucket_heuristic.zig) |

The package is registered in the shared `i64_array_bytes_output` runner and
verifier. Its static workload and inventory helpers remain unrun.
