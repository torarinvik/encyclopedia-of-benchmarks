# Circular SCAN disk scheduling

Order disk requests around the starting head position using the pinned Java `CircularScanScheduling.execute` behavior.

## Contract

The `i64_array_bytes_output` input is `[disk_size, start_position, moving_up, request_count, requests...]`. `disk_size` is the exclusive upper bound and must be in `1..128`; `start_position` must be in `0..disk_size-1`; `moving_up` is `1` for the upward branch and `0` for the downward branch; and `request_count` is in `0..64`. The packed input must contain exactly the declared requests, each in `[-128, 127]`.

The benchmark preserves the source's branch order, including its endpoint and wrap behavior. For `moving_up=1`, requests from the starting position up to (but excluding) `disk_size` are visited in ascending order, followed by every request below the start in ascending order. For `moving_up=0`, requests at or below the start are visited in descending order, followed by every request above the start in descending order. This means requests equal to the start are included, negative requests can appear in the upward wrap segment, and the downward wrap segment can include values at or above `disk_size`. Duplicates are preserved.

The successful result is the number of visited requests. Output is one byte per request in service order; negative values use their two's-complement byte representation. Invalid input returns `-1`; a null or undersized output buffer returns `-2`. An empty request list succeeds with zero output bytes.

## Source

The pinned Java [`CircularScanScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/diskscheduling/CircularScanScheduling.java) copies and sorts requests, then partitions them according to the initial direction and current position. The benchmark's output sequence captures the final current position as its last element when a request is visited.

## Workload and recording

[`workload.json`](workload.json) covers endpoint inclusion, both wrap branches, signed requests, out-of-disk requests retained by the source branch, duplicate requests, maximum-size input, malformed input, and insufficient output capacity.

The shared `i64_array_bytes_output` runner checks the return count and exact request sequence.

| Language | Source |
| --- | --- |
| C | [`c/c/circular_scan_scheduling.c`](../../../c/c/circular_scan_scheduling.c) |
| C3 | [`c3/c/circular_scan_scheduling.c3`](../../../c3/c/circular_scan_scheduling.c3) |
| C++ | [`cpp/c/circular_scan_scheduling.cpp`](../../../cpp/c/circular_scan_scheduling.cpp) |
| Elisa | [`elisa/c/circular_scan_scheduling.elisa`](../../../elisa/c/circular_scan_scheduling.elisa) |
| Nim | [`nim/c/circular_scan_scheduling.nim`](../../../nim/c/circular_scan_scheduling.nim) |
| Odin | [`odin/c/circular_scan_scheduling.odin`](../../../odin/c/circular_scan_scheduling.odin) |
| Rust | [`rust/c/circular_scan_scheduling.rs`](../../../rust/c/circular_scan_scheduling.rs) |
| V | [`v/c/circular_scan_scheduling.v`](../../../v/c/circular_scan_scheduling.v) |
| Zig | [`zig/c/circular_scan_scheduling.zig`](../../../zig/c/circular_scan_scheduling.zig) |
