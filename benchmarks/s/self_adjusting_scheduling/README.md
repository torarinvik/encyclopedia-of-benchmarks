# Self-adjusting scheduling

This benchmark ports the `SelfAdjustingScheduling` task queue from the pinned
[TheAlgorithms/Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/SelfAdjustingScheduling.java).
The source orders tasks by ascending integer priority. Each selected task
increases its wait time and adds that cumulative wait time to its priority
before it is requeued.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[task_count, steps, priorities...]`.
  There are 1..16 tasks, 0..64 schedule steps, and exactly one signed-i32
  starting priority per task. Task names are represented by their zero-based
  input indices.
- Before every requested poll, all current priorities must be distinct. This
  makes the Java priority queue's priority-only comparison deterministic for
  the benchmark. `steps = 0` accepts duplicate priorities because no poll is
  requested. A tie after the final priority update is allowed; a tie before a
  later requested poll is invalid.
- A poll selects the task with the smallest current priority. Increase that
  task's wait time by one, add the new cumulative wait time to its priority,
  then requeue it. Reject an update that leaves the signed-i32 range; arithmetic
  is evaluated in a wider type before the range check.
- Output is one byte per selected task, containing its zero-based index, in
  schedule order. Invalid input or schedule state returns `-1`. Validate the
  complete schedule before checking output storage. A null output pointer or
  insufficient capacity returns `-2`, including when `steps = 0`; otherwise
  return the number of output bytes.
- The largest valid input contains 18 values; 19 values are parseable for a
  malformed-framing case. Maximum output is 64 bytes.

The independent oracle is
[`benchmarks/self_adjusting_scheduling_oracle.py`](../../self_adjusting_scheduling_oracle.py).
[`workload.json`](workload.json) covers changing queue order, task wait-time
accumulation, final-update ties, invalid pre-poll ties, signed-i32 boundaries,
zero steps, maximum steps, and output-buffer precedence.

## Language ports

| Language | Port |
| --- | --- |
| C | [`c/s/self_adjusting_scheduling.c`](../../../c/s/self_adjusting_scheduling.c) |
| C3 | [`c3/s/self_adjusting_scheduling.c3`](../../../c3/s/self_adjusting_scheduling.c3) |
| C++ | [`cpp/s/self_adjusting_scheduling.cpp`](../../../cpp/s/self_adjusting_scheduling.cpp) |
| Elisa | [`elisa/s/self_adjusting_scheduling.elisa`](../../../elisa/s/self_adjusting_scheduling.elisa) |
| Nim | [`nim/s/self_adjusting_scheduling.nim`](../../../nim/s/self_adjusting_scheduling.nim) |
| Odin | [`odin/s/self_adjusting_scheduling.odin`](../../../odin/s/self_adjusting_scheduling.odin) |
| Rust | [`rust/s/self_adjusting_scheduling.rs`](../../../rust/s/self_adjusting_scheduling.rs) |
| V | [`v/s/self_adjusting_scheduling.v`](../../../v/s/self_adjusting_scheduling.v) |
| Zig | [`zig/s/self_adjusting_scheduling.zig`](../../../zig/s/self_adjusting_scheduling.zig) |
