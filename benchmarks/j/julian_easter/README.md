# Julian Easter

## Contract

For a year from 1 through 9,999, calculate Easter using Meeus's Julian algorithm and return the date packed as `YYYYMMDD`. Other inputs return `-1`. The source constructs a UTC-midnight `DateTime`; the packed integer preserves its year, month, and day. The exported C ABI entry point is `int64_t julian_easter(int64_t year);`.

## Source review

The pinned C# method calculates `a = year % 4`, `b = year % 7`, `c = year % 19`, then derives `d` and `e` with the published Julian Easter formula. It computes the month by flooring `(d + e + 114) / 31` and the day from the remainder plus one. For supported positive years, the numerator is positive, so integer division matches the source's decimal floor operation. The year range matches `DateTime`'s supported years.

## Workload

[`workload.json`](workload.json) covers the lower year boundary, representative Julian Easter dates, the upper year boundary, and invalid years.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/j/julian_easter.c`](../../../c/j/julian_easter.c) |
| C3 | [`c3/j/julian_easter.c3`](../../../c3/j/julian_easter.c3) |
| C++ | [`cpp/j/julian_easter.cpp`](../../../cpp/j/julian_easter.cpp) |
| Elisa | [`elisa/j/julian_easter.elisa`](../../../elisa/j/julian_easter.elisa) |
| Nim | [`nim/j/julian_easter.nim`](../../../nim/j/julian_easter.nim) |
| Odin | [`odin/j/julian_easter.odin`](../../../odin/j/julian_easter.odin) |
| Rust | [`rust/j/julian_easter.rs`](../../../rust/j/julian_easter.rs) |
| V | [`v/j/julian_easter.v`](../../../v/j/julian_easter.v) |
| Zig | [`zig/j/julian_easter.zig`](../../../zig/j/julian_easter.zig) |

## TheAlgorithms reference

- [C# `JulianEaster.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/JulianEaster.cs)
