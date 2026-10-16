# Bitmask assignment count

Count the ways to give every person exactly one eligible task, with each task assigned to at most one person. This ports `AssignmentUsingBitmask.count_no_of_ways` from the pinned Python source.

Input is a flat signed 64-bit array beginning with `[people_count, total_tasks]`, followed by one row per person. Each row is encoded as `[eligible_entry_count, task_id...]`. People use zero-based row order; task IDs are one-based, matching the source. Bounds are 0–8 people, 0–12 tasks, and at most 12 eligibility entries per person. Task IDs must be in `1..total_tasks`; malformed inputs return `-1`.

The source appends one person entry for every listed eligibility item. Duplicate task IDs in one person's row are therefore retained as multiplicities and count the same assignment multiple times. Ports preserve this behavior. The DP recurrence processes tasks in ascending order and either skips each task or assigns it to one currently unassigned eligible person. The answer is the number of ways to assign all people; unused tasks are allowed. With zero people, the answer is one (the empty assignment); if there are too few tasks, the answer is zero.

The result is a signed 64-bit integer. At these bounds, the largest result with distinct eligibility entries is `12P8 = 19,958,400`. Allowing duplicates, a safe upper bound is `12P8 × 12^8 = 8,581,746,681,446,400`, which fits signed 64-bit. Input length is at most 106 values.

## Pinned source

[TheAlgorithms/Python `bitmask.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/dynamic_programming/bitmask.py) at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. The source uses a top-down memo table; ports use the equivalent bounded recurrence over task number and assigned-person mask.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bitmask_assignment_count.c`](../../../c/b/bitmask_assignment_count.c) |
| C3 | [`c3/b/bitmask_assignment_count.c3`](../../../c3/b/bitmask_assignment_count.c3) |
| C++ | [`cpp/b/bitmask_assignment_count.cpp`](../../../cpp/b/bitmask_assignment_count.cpp) |
| Elisa | [`elisa/b/bitmask_assignment_count.elisa`](../../../elisa/b/bitmask_assignment_count.elisa) |
| Nim | [`nim/b/bitmask_assignment_count.nim`](../../../nim/b/bitmask_assignment_count.nim) |
| Odin | [`odin/b/bitmask_assignment_count.odin`](../../../odin/b/bitmask_assignment_count.odin) |
| Rust | [`rust/b/bitmask_assignment_count.rs`](../../../rust/b/bitmask_assignment_count.rs) |
| V | [`v/b/bitmask_assignment_count.v`](../../../v/b/bitmask_assignment_count.v) |
| Zig | [`zig/b/bitmask_assignment_count.zig`](../../../zig/b/bitmask_assignment_count.zig) |
