# Job sequence with deadline

This benchmark preserves the pinned Python source’s rank-based job filter. Jobs are stably sorted by descending reward, then the source retains each job at one-based rank `i` exactly when its deadline is at least `i`. It does not assign time slots.

## Contract

Input is `[job_count, deadline_0, reward_0, ...]`, with 0..64 jobs, deadlines in [-1,64], rewards in [-1,000,000, 1,000,000], and exact packed length. Output is the number of retained job IDs; tie-sensitive IDs are omitted. Invalid input returns -1.

See the [workload](workload.json), [independent oracle](../../job_sequence_with_deadline_oracle.py), and pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/scheduling/job_sequence_with_deadline.py).

| Language | Port |
|---|---|
| C | [`c/j/job_sequence_with_deadline.c`](../../../c/j/job_sequence_with_deadline.c) |
| C3 | [`c3/j/job_sequence_with_deadline.c3`](../../../c3/j/job_sequence_with_deadline.c3) |
| C++ | [`cpp/j/job_sequence_with_deadline.cpp`](../../../cpp/j/job_sequence_with_deadline.cpp) |
| Elisa | [`elisa/j/job_sequence_with_deadline.elisa`](../../../elisa/j/job_sequence_with_deadline.elisa) |
| Nim | [`nim/j/job_sequence_with_deadline.nim`](../../../nim/j/job_sequence_with_deadline.nim) |
| Odin | [`odin/j/job_sequence_with_deadline.odin`](../../../odin/j/job_sequence_with_deadline.odin) |
| Rust | [`rust/j/job_sequence_with_deadline.rs`](../../../rust/j/job_sequence_with_deadline.rs) |
| V | [`v/j/job_sequence_with_deadline.v`](../../../v/j/job_sequence_with_deadline.v) |
| Zig | [`zig/j/job_sequence_with_deadline.zig`](../../../zig/j/job_sequence_with_deadline.zig) |
