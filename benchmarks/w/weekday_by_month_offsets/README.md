# Gregorian Weekday by Month Offsets

Compute the weekday of a Gregorian calendar date with the fixed month-offset recurrence used by the pinned Rust source. January and February are evaluated in the preceding year. The formula runs in constant time.

## Contract

- Input is exactly three signed 64-bit integers: [year, month, day].
- Years range from 100 through 9999.
- Dates must be valid in the proleptic Gregorian calendar. Invalid input returns -1.
- A valid result is a weekday number: Sunday 0, Monday 1, Tuesday 2, Wednesday 3, Thursday 4, Friday 5, Saturday 6.
- The function does not allocate or modify input.

The month offsets are [0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4]. The calculation uses adjusted_year + adjusted_year/4 - adjusted_year/100 + adjusted_year/400 + month_offset + day, reduced modulo seven. It is distinct from the Conway Doomsday rule in the [Doomsday benchmark](../../d/doomsday/README.md).

## Workload

[workload.json](workload.json) covers ordinary dates, month and year boundaries, leap days, century rules, invalid dates, malformed array lengths, and year limits.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/w/weekday_by_month_offsets.c](../../../c/w/weekday_by_month_offsets.c) |
| C3 | [c3/w/weekday_by_month_offsets.c3](../../../c3/w/weekday_by_month_offsets.c3) |
| C++ | [cpp/w/weekday_by_month_offsets.cpp](../../../cpp/w/weekday_by_month_offsets.cpp) |
| Elisa | [elisa/w/weekday_by_month_offsets.elisa](../../../elisa/w/weekday_by_month_offsets.elisa) |
| Nim | [nim/w/weekday_by_month_offsets.nim](../../../nim/w/weekday_by_month_offsets.nim) |
| Odin | [odin/w/weekday_by_month_offsets.odin](../../../odin/w/weekday_by_month_offsets.odin) |
| Rust | [rust/w/weekday_by_month_offsets.rs](../../../rust/w/weekday_by_month_offsets.rs) |
| V | [v/w/weekday_by_month_offsets.v](../../../v/w/weekday_by_month_offsets.v) |
| Zig | [zig/w/weekday_by_month_offsets.zig](../../../zig/w/weekday_by_month_offsets.zig) |

## Upstream reference

- [TheAlgorithms/Rust doomsday.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/doomsday.rs)

The source-backed oracle is implemented in [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py). Build with the i64_array_scalar ABI family and record with that runner.
