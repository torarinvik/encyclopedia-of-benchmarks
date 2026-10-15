# Speed conversions

This benchmark ports the pinned Python `convert_speed` function. It multiplies the input by the source unit's factor and then the destination unit's inverse factor, in that order, and rounds the result to three decimal places.

## Contract

- The binary64 pair ABI receives `[speed, route]`, where `route = source_unit_index * 4 + destination_unit_index`.
- Unit indices follow the source chart order: `km/h = 0`, `m/s = 1`, `mph = 2`, `knot = 3`.
- Speeds are bounded to `[0, 1,000,000]` for this benchmark. The route must be an integer in `[0, 15]`.
- Invalid speeds or routes return `-1.0`. This sentinel is outside the nonnegative output range.
- Valid calls preserve the pinned multiplication order and return the value rounded to three decimal places.

[`workload.json`](workload.json) includes all twelve source-documented unit directions, identity conversion, zero speed, and invalid selector and bound cases.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/speed_conversions.c`](../../../c/s/speed_conversions.c) |
| C3 | [`c3/s/speed_conversions.c3`](../../../c3/s/speed_conversions.c3) |
| C++ | [`cpp/s/speed_conversions.cpp`](../../../cpp/s/speed_conversions.cpp) |
| Elisa | [`elisa/s/speed_conversions.elisa`](../../../elisa/s/speed_conversions.elisa) |
| Nim | [`nim/s/speed_conversions.nim`](../../../nim/s/speed_conversions.nim) |
| Odin | [`odin/s/speed_conversions.odin`](../../../odin/s/speed_conversions.odin) |
| Rust | [`rust/s/speed_conversions.rs`](../../../rust/s/speed_conversions.rs) |
| V | [`v/s/speed_conversions.v`](../../../v/s/speed_conversions.v) |
| Zig | [`zig/s/speed_conversions.zig`](../../../zig/s/speed_conversions.zig) |

## Upstream source

- [TheAlgorithms/Python `speed_conversions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/speed_conversions.py)
