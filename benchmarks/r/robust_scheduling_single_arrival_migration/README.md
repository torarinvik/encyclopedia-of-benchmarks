# Robust scheduling: one arrival and bounded migration

This package profiles one transition of the simplified robust-scheduling
procedure in “Robust Scheduling Algorithms,” DOI
[`10.1007/978-1-4939-2864-4_499`](https://doi.org/10.1007/978-1-4939-2864-4_499).
It applies only the chapter's stated small-job and large-job steps when their
preconditions hold. It does not add startup handling or a fallback for a
large job when no eligible machine has enough removable work, and it makes no
3/2-competitiveness or migration-factor guarantee.

Input is `[m,n,OPT,p_new,(p_i,machine_i)*n]`: two or three identical
machines, one to eight already assigned jobs, an arriving job, and the
claimed optimum makespan for all old jobs plus the new one. All processing
times are integers in `[1,20]`. Each port recomputes this OPT exactly by
bounded assignment enumeration and rejects a mismatched claim.

If `2*p_new<=OPT`, the new job goes to a least-loaded machine, with ties
resolved by the lowest machine ID. Otherwise, the transition is accepted only
if some machine has enough old work to remove and every job on it is at most
`OPT/2`. The lowest-index eligible machine is selected. Jobs are removed in
input order until their total size reaches `p_new`; the new job is placed on
that machine, then removed jobs are reassigned in the same input order to the
currently least-loaded machine, again breaking ties by machine ID. This
deterministic input-order refinement pins choices left open in the chapter.

Output is `[OPT,migration_volume,assignment_0,...,assignment_n]` as signed
little-endian i64 values, where the final assignment is for the new job and
`migration_volume` sums the sizes of old jobs whose machine IDs changed.
Malformed inputs or a false OPT claim return `-1`; null output or
insufficient capacity returns `-2` without writing. The primary oracle
enumerates encoded assignments; the independent verifier uses recursive
partition enumeration.

| Language | Port |
|---|---|
| C | `c/r/robust_scheduling_single_arrival_migration.c` |
| C3 | `c3/r/robust_scheduling_single_arrival_migration.c3` |
| C++ | `cpp/r/robust_scheduling_single_arrival_migration.cpp` |
| Elisa | `elisa/r/robust_scheduling_single_arrival_migration.elisa` |
| Nim | `nim/r/robust_scheduling_single_arrival_migration.nim` |
| Odin | `odin/r/robust_scheduling_single_arrival_migration.odin` |
| Rust | `rust/r/robust_scheduling_single_arrival_migration.rs` |
| V | `v/r/robust_scheduling_single_arrival_migration.v` |
| Zig | `zig/r/robust_scheduling_single_arrival_migration.zig` |
