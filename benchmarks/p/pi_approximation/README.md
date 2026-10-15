# Pi approximation from supplied points

This benchmark evaluates the deterministic point-list form of Monte Carlo pi approximation. The caller supplies points in the unit square; the function counts points inside the quarter circle and scales that fraction by four.

## Contract

- Input is a list of 0 to 65,536 points. Each point has two finite binary64 coordinates `x` and `y` in `[0, 1]`.
- A point is inside when the binary64 expression `x * x + y * y <= 1.0` is true, including the axis boundary.
- For a nonempty list, return `4.0 * inside_count / point_count` using binary64 arithmetic.
- The empty list returns NaN, matching the source formula's `0.0 / 0.0` result.
- The ABI stores coordinates as an interleaved array `[x0, y0, x1, y1, ...]` plus the number of points.

`workload.json` includes the empty input, axis boundary, fully outside points, mixed classifications, and a deterministic 16 by 16 grid. The runner checks results with a relative tolerance of `1e-12`, and records NaN as the JSON string `"NaN"` because JSON has no numeric NaN value.

## Reviewed sources

- [TheAlgorithms/Java `PiApproximation.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PiApproximation.java) accepts caller-supplied points, counts `x*x + y*y <= 1`, and returns four times the inside fraction.
- [TheAlgorithms/C-Plus-Plus `approximate_pi.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/math/approximate_pi.cpp) exposes the same point-list contract and is cataloged as an alias of this benchmark.

The random-sample variants that generate their own points from a count use different input contracts and remain separate candidates.

## Build and record

Build the implementation and checker with the shared `float64_point_array` ABI, then record it with the point-array runner:

```sh
python3 benchmarks/build_abi.py --family float64_point_array --algorithm pi_approximation --language rust --with-checker
python3 benchmarks/run_float64_point_array.py --build-manifest build/float64_point_array/p/pi_approximation/rust/build.json
```
