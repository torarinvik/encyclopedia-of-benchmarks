# Circular LOOK disk scheduling

Order disk requests around the starting head position using the pinned Java `CircularLookScheduling.execute` behavior.

## Contract

The `i64_array_bytes_output` input is `[max_cylinder, start_position, moving_up, request_count, requests...]`. `max_cylinder` is the exclusive upper bound and must be in `1..128`; `start_position` must be in `0..max_cylinder-1`; `moving_up` is `1` for the upward branch and `0` for the downward branch; and `request_count` is in `0..64`. The packed input must contain exactly the declared request values, each in `[-128, 255]`.

The source filters out requests outside `[0, max_cylinder)` and requests equal to the starting position. It preserves duplicate requests. For `moving_up=1`, it visits requests greater than the start in ascending order, then requests below the start in ascending order. For `moving_up=0`, it visits requests below the start in descending order, then requests above the start in descending order. That second descending segment follows the source's `Collections.reverse(upRequests)` branch, even though conventional C-LOOK would usually visit that wrapped segment in ascending order. The benchmark preserves the pinned implementation's behavior.

The successful result is the number of visited requests. Output is one unsigned byte per cylinder number, in service order. Invalid input returns `-1`; a null or undersized output buffer returns `-2`. An empty service list succeeds with zero output bytes.

## Source

The pinned Java [`CircularLookScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/diskscheduling/CircularLookScheduling.java) filters requests against the configured cylinder bound, sorts the partitions around the current position, and updates its current position to the last serviced request. The final position is implicit in the output sequence, or unchanged when no request is serviced.

## Workload and recording

[`workload.json`](workload.json) covers both directions, the downward-wrap ordering in the source, duplicate and equal-to-start requests, out-of-range filtering, empty workloads, maximum-sized request lists, malformed input, and short output capacity.

The shared `i64_array_bytes_output` runner checks the return count and exact request sequence.

| Language | Source |
| --- | --- |
| C | [`c/c/circular_look_scheduling.c`](../../../c/c/circular_look_scheduling.c) |
| C3 | [`c3/c/circular_look_scheduling.c3`](../../../c3/c/circular_look_scheduling.c3) |
| C++ | [`cpp/c/circular_look_scheduling.cpp`](../../../cpp/c/circular_look_scheduling.cpp) |
| Elisa | [`elisa/c/circular_look_scheduling.elisa`](../../../elisa/c/circular_look_scheduling.elisa) |
| Nim | [`nim/c/circular_look_scheduling.nim`](../../../nim/c/circular_look_scheduling.nim) |
| Odin | [`odin/c/circular_look_scheduling.odin`](../../../odin/c/circular_look_scheduling.odin) |
| Rust | [`rust/c/circular_look_scheduling.rs`](../../../rust/c/circular_look_scheduling.rs) |
| V | [`v/c/circular_look_scheduling.v`](../../../v/c/circular_look_scheduling.v) |
| Zig | [`zig/c/circular_look_scheduling.zig`](../../../zig/c/circular_look_scheduling.zig) |
