# Job Scheduling With Deadline

This benchmark preserves the pinned Java implementation's greedy schedule for jobs with arrival times, deadlines, and profits. Jobs are stably sorted by descending profit, so equal-profit jobs retain their input order. Each feasible job takes the latest free slot from its deadline backward through its arrival time. A job whose arrival is later than its deadline is accepted but skipped.

## Contract

- Input is a signed 64-bit array encoded as [n, (id, arrival, deadline, profit) repeated n times]. The job count is 0 through 128, the exact length is 1 + 4*n, and the maximum length is 513.
- IDs are unique integers from 0 through 2,147,483,647. Arrival and deadline are each from 1 through 32. Profit is from -1,000,000 through 1,000,000. An arrival later than its deadline is valid and makes that job unschedulable.
- Jobs are processed in stable descending-profit order. For each job with arrival <= deadline, scan slots backward from min(deadline - 1, max_deadline - 1) through arrival - 1 and place the job in the first free slot.
- The result packs the scheduled-job count in the high 32 bits and the signed 32-bit total profit in the low 32 bits. Decode the high word as an unsigned count and the low word as a signed integer. The bounds keep the profit sum in signed 32-bit range. Empty input [0] returns zero.
- Malformed length/count, duplicate or out-of-range IDs, and out-of-range arrival, deadline, or profit values return -1.

The [workload](workload.json) covers stable ties, release-window contention, infeasible jobs, negative profits, identifier bounds, maximum job count, and malformed records. The [independent oracle](../../job_scheduling_with_deadline_oracle.py) uses a set of occupied slots as a separate reference representation.

## Upstream source

- [Java JobSchedulingWithDeadline.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/JobSchedulingWithDeadline.java)

Build with python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm job_scheduling_with_deadline --language c and record with benchmarks/run_i64_array_scalar.py.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/j/job_scheduling_with_deadline.c](../../../c/j/job_scheduling_with_deadline.c) |
| C3 | [c3/j/job_scheduling_with_deadline.c3](../../../c3/j/job_scheduling_with_deadline.c3) |
| C++ | [cpp/j/job_scheduling_with_deadline.cpp](../../../cpp/j/job_scheduling_with_deadline.cpp) |
| Elisa | [elisa/j/job_scheduling_with_deadline.elisa](../../../elisa/j/job_scheduling_with_deadline.elisa) |
| Nim | [nim/j/job_scheduling_with_deadline.nim](../../../nim/j/job_scheduling_with_deadline.nim) |
| Odin | [odin/j/job_scheduling_with_deadline.odin](../../../odin/j/job_scheduling_with_deadline.odin) |
| Rust | [rust/j/job_scheduling_with_deadline.rs](../../../rust/j/job_scheduling_with_deadline.rs) |
| V | [v/j/job_scheduling_with_deadline.v](../../../v/j/job_scheduling_with_deadline.v) |
| Zig | [zig/j/job_scheduling_with_deadline.zig](../../../zig/j/job_scheduling_with_deadline.zig) |
