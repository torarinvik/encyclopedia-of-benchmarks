# Geofence

The pinned C# `Geofence.IsInside` calls `GeoLocation.CalculateDistanceFromLatLng` and returns whether that spherical distance is less than or equal to the configured radius. The helper uses the Haversine formula with Earth radius 6,371.01 km. The existing Haversine benchmark uses a 6,371 km radius and returns distance, so this contract preserves the distinct inclusive radius predicate and source radius.

## Contract

The `i64_array_scalar` input is five integers: `[center_lat_microdegrees, center_lon_microdegrees, point_lat_microdegrees, point_lon_microdegrees, radius_millimeters]`. Latitude is bounded to ±90 degrees, longitude to ±180 degrees, and radius to -1,000 through 30,000,000,000 millimeters. Negative radius is accepted and returns outside for valid coordinates, matching the source comparison. The output is 1 when the spherical distance is at most the radius, otherwise 0. Invalid length or bounds return -1.

The calculation converts microdegrees to radians, evaluates the Haversine term, clamps it to [0,1] for endpoint rounding, computes `6371010 * 2 * atan2(sqrt(a), sqrt(1-a))` meters, then compares to radius millimeters divided by 1,000. Same-point radius zero exercises the inclusive equality case.

Run `python3 benchmarks/verify_geofence.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to validate all nine ports.
