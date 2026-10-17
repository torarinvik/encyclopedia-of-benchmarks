# Shortest seek time first disk scheduling

Service each pending disk request by choosing the track nearest to the current head position. The implementation preserves the pinned Java source's request iteration order when distances tie, including duplicate requests.

## Contract

The i64_array_bytes_output input is [initial_track, request_count, requests...]. The initial track and every request must be in 0..255; the request count must be in 0..64; and the input must contain exactly 2 + request_count signed 64-bit values. Duplicate requests are preserved and serviced individually. At every step, the earliest still-pending request wins a distance tie. The current head moves to the selected request before the next choice.

The function returns the number of requests serviced and writes one unsigned byte per selected track, in service order. Invalid input returns -1. A null output pointer always returns -2, including an empty request list. An undersized output buffer returns -2 without writing output. A non-null output pointer with zero capacity succeeds when the request list is empty.

The bounded track range keeps distance arithmetic safe, and the at-most-64 requests make the source's repeated linear scan practical. Each call starts at the supplied initial track and does not retain state.

## Workload and recording

The [workload](workload.json) covers nearest-request order, stable tie behavior, reversed input tie order, duplicate requests, byte boundaries, empty and maximum-sized lists, malformed frames, null output, and insufficient capacity. The shortest_seek_time_first oracle models each choice independently from the source code's scan-and-remove behavior.

The shared i64_array_bytes_output runner checks the return count and exact byte sequence.

## Source

The pinned Java [SSFScheduling.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/diskscheduling/SSFScheduling.java) scans pending requests for the minimum absolute distance from its mutable current track. It replaces the winner only for a strictly smaller distance, then removes the first matching request and updates the head position.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/shortest_seek_time_first.c](../../../c/s/shortest_seek_time_first.c) |
| C3 | [c3/s/shortest_seek_time_first.c3](../../../c3/s/shortest_seek_time_first.c3) |
| C++ | [cpp/s/shortest_seek_time_first.cpp](../../../cpp/s/shortest_seek_time_first.cpp) |
| Elisa | [elisa/s/shortest_seek_time_first.elisa](../../../elisa/s/shortest_seek_time_first.elisa) |
| Nim | [nim/s/shortest_seek_time_first.nim](../../../nim/s/shortest_seek_time_first.nim) |
| Odin | [odin/s/shortest_seek_time_first.odin](../../../odin/s/shortest_seek_time_first.odin) |
| Rust | [rust/s/shortest_seek_time_first.rs](../../../rust/s/shortest_seek_time_first.rs) |
| V | [v/s/shortest_seek_time_first.v](../../../v/s/shortest_seek_time_first.v) |
| Zig | [zig/s/shortest_seek_time_first.zig](../../../zig/s/shortest_seek_time_first.zig) |
