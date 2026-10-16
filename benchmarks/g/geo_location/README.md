# Geo location distance

Compute the spherical distance between two latitude/longitude points. This follows the pinned C# `GeoLocation.CalculateDistanceFromLatLng` formula, including its Earth radius of 6371.01 km and meter-valued output. It is separate from [`haversine_distance`](../../h/haversine_distance/README.md), which uses a 6371 km radius and returns kilometers.

Input is `[latitude1, longitude1, latitude2, longitude2]` in degrees. Latitudes must be in `[-90, 90]`, longitudes in `[-180, 180]`, and all inputs must be finite. The Haversine term must remain within `[0, 1]`; values outside that range are invalid instead of producing a square root of a negative number. Output is one binary64 distance in meters. Invalid input returns `-1`; a null or undersized output buffer returns `-2`.

See [`workload.json`](workload.json), the [independent oracle](../../geo_location_oracle.py), and the [pinned C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6/Algorithms/Other/GeoLocation.cs).

| Language | Port |
|---|---|
| C | [`c/g/geo_location.c`](../../../c/g/geo_location.c) |
| C3 | [`c3/g/geo_location.c3`](../../../c3/g/geo_location.c3) |
| C++ | [`cpp/g/geo_location.cpp`](../../../cpp/g/geo_location.cpp) |
| Elisa | [`elisa/g/geo_location.elisa`](../../../elisa/g/geo_location.elisa) |
| Nim | [`nim/g/geo_location.nim`](../../../nim/g/geo_location.nim) |
| Odin | [`odin/g/geo_location.odin`](../../../odin/g/geo_location.odin) |
| Rust | [`rust/g/geo_location.rs`](../../../rust/g/geo_location.rs) |
| V | [`v/g/geo_location.v`](../../../v/g/geo_location.v) |
| Zig | [`zig/g/geo_location.zig`](../../../zig/g/geo_location.zig) |
