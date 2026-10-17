# Rhumb-line bearing

This benchmark ports the pinned Rust `rhumb_bearing` method and reports a rhumb-line bearing in degrees.

## Contract

- The ABI is `float64_slice_io`. Input is exactly `[latitude1_deg, longitude1_deg, latitude2_deg, longitude2_deg]`; all values must be finite, latitudes must be in `[-85,85]`, and longitudes in `[-180,180]`.
- Preserve the source operation order: convert latitudes to radians; calculate and wrap the longitude delta once only when it is strictly outside `[-PI,PI]`; compute the Mercator latitude difference; evaluate `atan2(del_lambda, del_psi) * 180 / PI`; then return `(bearing + 360) % 360`. Exact half-turn deltas remain at `+PI` or `-PI`.
- Success writes one bearing in `[0,360)` degrees and returns 1. Invalid framing or coordinates return `-1` before output checks. A null output or capacity below one returns `-2` without writes. Comparisons use absolute tolerance `1e-10` degrees and relative tolerance `1e-12`.

The workload covers identical points, cardinal and diagonal paths, both antimeridian directions, exact half-turns, domain limits, malformed inputs, and ABI errors. See [workload.json](workload.json) and the independent [oracle](../../rhumb_bearing_oracle.py).

The source is Rust [`rhumb_bearing`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/navigation/rhumbline.rs), pinned at commit `fed66cb0c74c4a939ec5163648458a8c2b46fd4c`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm rhumb_bearing --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm rhumb_bearing
python3 benchmarks/verify_float64_slice_io.py --algorithm rhumb_bearing --languages rust
~~~

## Language ports

Ports will be listed here as they land.
