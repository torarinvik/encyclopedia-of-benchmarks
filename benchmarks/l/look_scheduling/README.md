# LOOK Disk Scheduling

This package ports the pinned Java LOOK request-ordering algorithm. It models one fresh scheduler instance and one `execute` call per benchmark invocation. Requests outside the configured track range are ignored, and duplicate requests remain in the service order.

## Contract

- The `i64_array_scalar` input is `[max_track, start_position, initial_direction, request_count, request_0, ..., request_(request_count-1)]` with exact length `request_count + 4`.
- `max_track` is `1..256`, `start_position` is `0..max_track-1`, direction is `0=down` or `1=up`, and request count is `0..4096`. Request values must fit signed 32-bit. Valid tracks are `0..max_track-1`; values outside that range are ignored, matching the source.
- Requests below the start position form the lower side; requests equal to or above the start form the upper side. Both sides are sorted ascending. Moving up services the upper side ascending, then the lower side descending. Moving down services the lower side descending, then the upper side ascending.
- The source toggles direction once per `execute` call, including when no requests are valid. For this fresh-instance single-call contract, `current_position` remains the start position, and `farthest_position` is the maximum valid requested track or zero if none are valid.
- Invalid length, bounds, direction, or signed-i32 request values returns `-1`.
- The output record is `[served_count, serviced_requests..., final_direction, farthest_position, current_position]`. The scalar result is the low 63 bits of FNV-1a-64 over that record encoded as signed-i64 little-endian words. The offset basis is `14695981039346656037` and the prime is `1099511628211`.

The [independent oracle](../../look_scheduling_oracle.py) sorts the two request partitions directly; the language ports use bounded track-frequency arrays. The [workload](workload.json) covers both directions, equal-start requests, duplicates, filtered requests, empty inputs, track boundaries, the maximum request count, and invalid records.

## Upstream source

- [TheAlgorithms/Java `LookScheduling.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/scheduling/diskscheduling/LookScheduling.java)

| Language | Port |
|---|---|
| C | [`c/l/look_scheduling.c`](../../../c/l/look_scheduling.c) |
| C3 | [`c3/l/look_scheduling.c3`](../../../c3/l/look_scheduling.c3) |
| C++ | [`cpp/l/look_scheduling.cpp`](../../../cpp/l/look_scheduling.cpp) |
| Elisa | [`elisa/l/look_scheduling.elisa`](../../../elisa/l/look_scheduling.elisa) |
| Nim | [`nim/l/look_scheduling.nim`](../../../nim/l/look_scheduling.nim) |
| Odin | [`odin/l/look_scheduling.odin`](../../../odin/l/look_scheduling.odin) |
| Rust | [`rust/l/look_scheduling.rs`](../../../rust/l/look_scheduling.rs) |
| V | [`v/l/look_scheduling.v`](../../../v/l/look_scheduling.v) |
| Zig | [`zig/l/look_scheduling.zig`](../../../zig/l/look_scheduling.zig) |
