# Job sequencing with deadline

This benchmark ports the pinned Python greedy job scheduler. Jobs are processed in stable descending profit order and each job is assigned to the latest free slot no later than its deadline.

## Contract

Input is `[job_count, deadline_0, profit_0, ...]`, with 1..32 jobs, deadlines in 0..32, profits in 0..1,000,000, and exact packed length. Job IDs are omitted because the numeric output captures the returned count and total profit: `count * 32,000,001 + profit`. Decode with quotient and remainder by 32,000,001. The base exceeds the maximum total profit (32,000,000), so the encoding is injective. Empty job arrays are invalid because the pinned Python source calls `max()` on the job list. Invalid inputs return -1.

See the [workload](workload.json), [independent oracle](../../job_sequencing_with_deadline_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/job_sequencing_with_deadline.py).

| Language | Port |
|---|---|
| C | [`c/j/job_sequencing_with_deadline.c`](../../../c/j/job_sequencing_with_deadline.c) |
| C3 | [`c3/j/job_sequencing_with_deadline.c3`](../../../c3/j/job_sequencing_with_deadline.c3) |
| C++ | [`cpp/j/job_sequencing_with_deadline.cpp`](../../../cpp/j/job_sequencing_with_deadline.cpp) |
| Elisa | [`elisa/j/job_sequencing_with_deadline.elisa`](../../../elisa/j/job_sequencing_with_deadline.elisa) |
| Nim | [`nim/j/job_sequencing_with_deadline.nim`](../../../nim/j/job_sequencing_with_deadline.nim) |
| Odin | [`odin/j/job_sequencing_with_deadline.odin`](../../../odin/j/job_sequencing_with_deadline.odin) |
| Rust | [`rust/j/job_sequencing_with_deadline.rs`](../../../rust/j/job_sequencing_with_deadline.rs) |
| V | [`v/j/job_sequencing_with_deadline.v`](../../../v/j/job_sequencing_with_deadline.v) |
| Zig | [`zig/j/job_sequencing_with_deadline.zig`](../../../zig/j/job_sequencing_with_deadline.zig) |
