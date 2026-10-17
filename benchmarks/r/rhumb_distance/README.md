# Rhumb-line distance

This benchmark ports the pinned Rust `rhumb_dist` method for the distance between two geographic coordinates along a rhumb line.

## Contract

- The ABI is `float64_slice_io`. Input is exactly four finite binary64 values `[lat1_deg, long1_deg, lat2_deg, long2_deg]`; latitudes are in `[-85,85]` degrees and longitudes in `[-180,180]` degrees. The maximum valid input length is 4 values; one additional value is parseable only so trailing data can be rejected.
- Preserve the source's operation order: convert latitudes to radians, compute the latitude and longitude deltas, wrap the longitude delta once when it is greater than `PI` or less than `-PI`, compute the Mercator latitude difference, and use `q = del_phi/del_psi` only when `abs(del_psi) > 1e-12`; otherwise use `cos(phi1)`. The distance is `sqrt(del_phi^2 + (q*del_lambda)^2) * 6,371,000` meters.
- Success writes one binary64 distance and returns 1. Invalid framing, nonfinite values, or out-of-domain coordinates return `-1` before output checks. A null output pointer or capacity below one value returns `-2` without writes. Comparisons use absolute tolerance `1e-7` meters and relative tolerance `1e-12`.

The workload covers identical points, east-west and meridional paths, diagonal paths, both antimeridian directions, the near-zero `del_psi` branch, the strict half-turn boundary, domain limits, malformed input, and output-buffer errors. See [workload.json](workload.json) and the independent [oracle](../../rhumb_distance_oracle.py).

The source is Rust [`rhumb_dist`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/navigation/rhumbline.rs), pinned at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`. The same file's `rhumb_bearing` and `rhumb_destination` methods are separate benchmarks with separate contracts.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm rhumb_distance --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm rhumb_distance
python3 benchmarks/verify_float64_slice_io.py --algorithm rhumb_distance --languages rust
~~~

## Language ports

- C: [c/r/rhumb_distance.c](../../../c/r/rhumb_distance.c)
- C3: [c3/r/rhumb_distance.c3](../../../c3/r/rhumb_distance.c3)
- C++: [cpp/r/rhumb_distance.cpp](../../../cpp/r/rhumb_distance.cpp)
- Elisa: [elisa/r/rhumb_distance.elisa](../../../elisa/r/rhumb_distance.elisa)
- Nim: [nim/r/rhumb_distance.nim](../../../nim/r/rhumb_distance.nim)
- Odin: [odin/r/rhumb_distance.odin](../../../odin/r/rhumb_distance.odin)
- Rust: [rust/r/rhumb_distance.rs](../../../rust/r/rhumb_distance.rs)
- V: [v/r/rhumb_distance.v](../../../v/r/rhumb_distance.v)
- Zig: [zig/r/rhumb_distance.zig](../../../zig/r/rhumb_distance.zig)
