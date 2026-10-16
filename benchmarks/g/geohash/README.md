# Geohash

The pinned C# `Geohash.Encode` alternates longitude and latitude bisections, beginning with longitude. For each bit it chooses the upper interval only when the coordinate is strictly greater than the midpoint; midpoint equality selects the lower interval. Each five-bit group indexes the alphabet `0123456789bcdefghjkmnpqrstuvwxyz`. The source emits exactly 12 characters.

## Contract

The `i64_array_bytes_output` input is `[latitude_microdegrees, longitude_microdegrees]`, with latitude in [-90, 90] degrees and longitude in [-180, 180] degrees. The two values are converted to degrees before encoding. The output is the exact 12-byte ASCII geohash. Invalid length or coordinate bounds return -1; insufficient output capacity returns -2.

The fixed-point input keeps coordinate transport identical across ports. The bisection uses binary64 values and the source's strict `>` midpoint rule, including at the geographic endpoints.

Run `python3 benchmarks/verify_geohash.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` to check all nine implementations.
