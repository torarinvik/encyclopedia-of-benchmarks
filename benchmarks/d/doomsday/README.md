# Doomsday Rule Weekday

Compute the weekday of a Gregorian calendar date with Conway's Doomsday rule. The implementation finds the century anchor, derives that year's Doomsday weekday, and offsets from a known month anchor in constant time.

## Contract

- Input is exactly three signed 64-bit integers: [year, month, day].
- Years range from 100 through 9999, matching the Python source's requirement that the year use at least three decimal digits.
- Dates must be valid in the proleptic Gregorian calendar. Invalid input returns -1.
- A valid result is a weekday number: Sunday 0, Monday 1, Tuesday 2, Wednesday 3, Thursday 4, Friday 5, Saturday 6.
- The function does not allocate or modify input.

The pinned Python source implements the Doomsday rule and returns weekday names. The pinned Rust file with the same candidate name uses a different month-offset weekday formula; this package selects the actual Doomsday method and normalizes both source APIs to the shared numeric weekday contract. Unlike the existing [Zeller's congruence benchmark](../../z/zellers_congruence/README.md), this package preserves the Doomsday-rule calculation.

## Workload

[workload.json](workload.json) includes the Python examples, leap days, century boundaries, year limits, malformed array lengths, and invalid dates. Expected weekday indices use Sunday as zero.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/d/doomsday.c](../../../c/d/doomsday.c) |
| C3 | [c3/d/doomsday.c3](../../../c3/d/doomsday.c3) |
| C++ | [cpp/d/doomsday.cpp](../../../cpp/d/doomsday.cpp) |
| Elisa | [elisa/d/doomsday.elisa](../../../elisa/d/doomsday.elisa) |
| Nim | [nim/d/doomsday.nim](../../../nim/d/doomsday.nim) |
| Odin | [odin/d/doomsday.odin](../../../odin/d/doomsday.odin) |
| Rust | [rust/d/doomsday.rs](../../../rust/d/doomsday.rs) |
| V | [v/d/doomsday.v](../../../v/d/doomsday.v) |
| Zig | [zig/d/doomsday.zig](../../../zig/d/doomsday.zig) |

## Upstream references

- [TheAlgorithms/Python doomsday.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/doomsday.py)
- [TheAlgorithms/Rust doomsday.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/math/doomsday.rs)

The source-backed weekday oracle is implemented in `benchmarks/run_i64_array_scalar.py`. Build with the i64_array_scalar ABI family and record with that runner.
