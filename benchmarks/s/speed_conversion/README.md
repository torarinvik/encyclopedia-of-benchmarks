# Speed conversion

This benchmark ports the pinned PHP `convertSpeed` function. It converts speeds among miles per hour, kilometers per hour, meters per second, feet per second, and knots by multiplying first by the source-unit factor and then by the destination-unit multiplier, followed by PHP-compatible rounding to two decimal places.

## Contract

- The `float64_pair` ABI accepts `[speed, route]` as binary64 values. `route` encodes the source and destination as `source_index * 5 + destination_index`.
- Unit indices follow the pinned PHP order: `mph = 0`, `km/h = 1`, `m/s = 2`, `ft/s = 3`, and `kn = 4`.
- Speed is in `[0, 1,000,000]`; route is an integer from 0 through 24.
- Source factors are `[1.609344, 1, 3.6, 1.097, 1.852]`. Destination multipliers are `[0.6213712, 1, 0.277778, 0.911344, 0.539957]`.
- The result is `round(speed * source_factor * destination_multiplier, 2)`, preserving that multiplication order and PHP's default positive half-up rounding. Invalid speeds or routes return `-1.0`.

[`workload.json`](workload.json) covers every source/destination pair, identity routes, zero and fractional speeds, rounding, limits, and invalid selectors.

## Build

```sh
python3 benchmarks/build_abi.py --family float64_pair --algorithm speed_conversion --language rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/speed_conversion.c`](../../../c/s/speed_conversion.c) |
| C3 | [`c3/s/speed_conversion.c3`](../../../c3/s/speed_conversion.c3) |
| C++ | [`cpp/s/speed_conversion.cpp`](../../../cpp/s/speed_conversion.cpp) |
| Elisa | [`elisa/s/speed_conversion.elisa`](../../../elisa/s/speed_conversion.elisa) |
| Nim | [`nim/s/speed_conversion.nim`](../../../nim/s/speed_conversion.nim) |
| Odin | [`odin/s/speed_conversion.odin`](../../../odin/s/speed_conversion.odin) |
| Rust | [`rust/s/speed_conversion.rs`](../../../rust/s/speed_conversion.rs) |
| V | [`v/s/speed_conversion.v`](../../../v/s/speed_conversion.v) |
| Zig | [`zig/s/speed_conversion.zig`](../../../zig/s/speed_conversion.zig) |

## Pinned source

- PHP [`SpeedConversion.php`](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/Conversions/SpeedConversion.php)
