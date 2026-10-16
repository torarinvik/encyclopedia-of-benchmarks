# Lambert ellipsoidal distance

The pinned Python routine converts geodetic latitudes to reduced latitudes, obtains the central angle from its Haversine helper, and applies Lambert’s ellipsoidal X/Y correction with WGS-84 axes. The result is in meters.

## Contract

Input is four microdegree coordinates `[lat1,lon1,lat2,lon2]`. Latitude is bounded to ±90° and longitude to ±180°. Identical coordinate tuples are invalid because the source formula divides by `sin(sigma/2)^2`; invalid inputs return -1e300. Output is the source’s Lambert distance in meters, compared with 1e-6 absolute and 1e-12 relative tolerance.

See [workload](workload.json), [oracle](../../lamberts_ellipsoidal_distance_oracle.py), pinned [Lambert source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geodesy/lamberts_ellipsoidal_distance.py), and its [Haversine helper](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geodesy/haversine_distance.py).

| Language | Port |
|---|---|
| C | c/l/lamberts_ellipsoidal_distance.c |
| C3 | c3/l/lamberts_ellipsoidal_distance.c3 |
| C++ | cpp/l/lamberts_ellipsoidal_distance.cpp |
| Elisa | elisa/l/lamberts_ellipsoidal_distance.elisa |
| Nim | nim/l/lamberts_ellipsoidal_distance.nim |
| Odin | odin/l/lamberts_ellipsoidal_distance.odin |
| Rust | rust/l/lamberts_ellipsoidal_distance.rs |
| V | v/l/lamberts_ellipsoidal_distance.v |
| Zig | zig/l/lamberts_ellipsoidal_distance.zig |
