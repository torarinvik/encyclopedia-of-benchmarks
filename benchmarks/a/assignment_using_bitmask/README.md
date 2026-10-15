# Assignment Counting with Bitmask DP

This benchmark is based on the pinned [TheAlgorithms/Java `AssignmentUsingBitmask`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/dynamicprogramming/AssignmentUsingBitmask.java). The source counts ways to give every person one eligible, distinct task, processing tasks in order and memoizing by the assigned-person bitmask and task index. The portable contract uses the same count and state representation, with zero-based task bits.

The `i64_array_scalar` input is `[person_count, task_count, eligible_task_mask_per_person...]`. Bit `j` in a person's mask means that person can perform task `j`. Each task can be assigned to at most one person; tasks may be skipped, and every person must receive exactly one eligible task. The result is the number of valid assignments. Zero people has one empty assignment; otherwise, no complete assignment returns zero. Invalid input returns `-1`.

The input supports 0–10 people and 0–10 tasks. Each eligibility mask must be between zero and `(1 << task_count) - 1`, and the input must contain exactly one mask per person. For the all-eligible case, the maximum count is `10!`, which stays within the Java source's signed 32-bit result range.

The ports process tasks in order with a bitmask DP: each state either skips the current task or assigns it to one eligible unassigned person. This is the bottom-up form of the source's memoized recurrence. Runtime is O(T × P × 2^P) and auxiliary space is O(2^P), where `P` is the person count and `T` is the task count.

[`workload.json`](workload.json) contains representative matching, no-solution, empty, and malformed cases.

The source-backed expected-value check is in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

| Language | Implementation |
| --- | --- |
| C | [`c/a/assignment_using_bitmask.c`](../../../c/a/assignment_using_bitmask.c) |
| C3 | [`c3/a/assignment_using_bitmask.c3`](../../../c3/a/assignment_using_bitmask.c3) |
| C++ | [`cpp/a/assignment_using_bitmask.cpp`](../../../cpp/a/assignment_using_bitmask.cpp) |
| Elisa | [`elisa/a/assignment_using_bitmask.elisa`](../../../elisa/a/assignment_using_bitmask.elisa) |
| Nim | [`nim/a/assignment_using_bitmask.nim`](../../../nim/a/assignment_using_bitmask.nim) |
| Odin | [`odin/a/assignment_using_bitmask.odin`](../../../odin/a/assignment_using_bitmask.odin) |
| Rust | [`rust/a/assignment_using_bitmask.rs`](../../../rust/a/assignment_using_bitmask.rs) |
| V | [`v/a/assignment_using_bitmask.v`](../../../v/a/assignment_using_bitmask.v) |
| Zig | [`zig/a/assignment_using_bitmask.zig`](../../../zig/a/assignment_using_bitmask.zig) |
