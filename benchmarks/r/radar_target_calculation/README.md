# Radar Target Calculation

This package ports the bounded `calculate_target_coordinates` function from the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geodesy/radar_target_calculation.py). It converts radar latitude, longitude, altitude, azimuth, range, and elevation into target latitude, longitude, and altitude using WGS84 geodetic/ECEF conversions and a local ENU offset.

The float64 input is `[radar_latitude_degrees, radar_longitude_degrees, radar_altitude_meters, azimuth_degrees, range_meters, elevation_degrees]`. Inputs must be finite and lie in these closed bounds: latitude `[-80, 80]`, longitude `[-180, 180]`, radar altitude `[-1000, 10000]`, azimuth `[-360, 360]`, range `[0, 200000]`, and elevation `[-30, 30]`. The bounded latitude and range keep the ECEF-to-geodetic altitude calculation away from its polar singularity. The output is `[target_latitude_degrees, target_longitude_degrees, target_altitude_meters]`.

The ports preserve the source's WGS84 constants, transform formulas, and calculation order. Invalid input returns `-1` without writing output. A null or undersized output buffer returns `-2`, also without writing. Output comparison uses absolute tolerance `1e-6` and relative tolerance `1e-12` for small standard-library math differences. The independent oracle and corpus are [`radar_target_calculation_oracle.py`](../../radar_target_calculation_oracle.py) and [`workload.json`](workload.json).

| Language | Port |
|---|---|
| C | [`c/r/radar_target_calculation.c`](../../../c/r/radar_target_calculation.c) |
| C3 | [`c3/r/radar_target_calculation.c3`](../../../c3/r/radar_target_calculation.c3) |
| C++ | [`cpp/r/radar_target_calculation.cpp`](../../../cpp/r/radar_target_calculation.cpp) |
| Elisa | [`elisa/r/radar_target_calculation.elisa`](../../../elisa/r/radar_target_calculation.elisa) |
| Nim | [`nim/r/radar_target_calculation.nim`](../../../nim/r/radar_target_calculation.nim) |
| Odin | [`odin/r/radar_target_calculation.odin`](../../../odin/r/radar_target_calculation.odin) |
| Rust | [`rust/r/radar_target_calculation.rs`](../../../rust/r/radar_target_calculation.rs) |
| V | [`v/r/radar_target_calculation.v`](../../../v/r/radar_target_calculation.v) |
| Zig | [`zig/r/radar_target_calculation.zig`](../../../zig/r/radar_target_calculation.zig) |
