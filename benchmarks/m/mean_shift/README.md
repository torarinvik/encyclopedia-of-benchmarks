# Mean shift

This package specializes the pinned Python
[`mean_shift`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/mean_shift.py)
function. It shifts each point toward the mean of source points in its
bandwidth window, greedily merges candidate centroids, then assigns each
original point to the nearest retained centroid.

## Contract

The `float64_slice_io` input is
`[point_count, dimension, bandwidth, max_iterations, tolerance, coordinates…]`.
The first five values are finite binary64 numbers; the three count fields must
be exact integers. Coordinates are flattened point-major, with exactly
`point_count * dimension` values. There are 1–16 points, 1–3 dimensions,
coordinates in `[-10, 10]`, bandwidth in `[0.5, 20]`, 1–64 iterations, and
tolerance in `[1e-5, 1e-2]`. The maximum valid input length is 53 doubles; 54
values are parseable so an extra trailing value can be rejected.

Preserve the source's binary64 operation order: Euclidean distance is
`sum((a - b) ** 2 for a, b in zip(point_a, point_b)) ** 0.5`, window
membership uses `distance <= bandwidth`, means sum each coordinate in source
point order and divide by the neighbor count, and convergence uses strict
`distance < tolerance`. The source checks convergence candidates in order and
stops at the first non-converged candidate. Every bandwidth or convergence
decision reached by that control flow must be at least `1e-6` away from its
threshold; otherwise the input is invalid. During nearest-centroid assignment,
every non-equal distance compared with the current best must also differ by at
least `1e-6`; exact ties remain valid and keep the first centroid. These margins
keep the discrete decisions stable across the ports.

Candidate points start in input order and each update reads the original data
in input order. If every candidate converges, the source breaks before
assigning the newly computed candidates, so the previously stored candidates
are merged. Merging is greedy: retain a candidate only when it is at least a
bandwidth away from every centroid already retained. Labels are zero-based,
follow the original point order, and nearest-centroid ties select the first
retained centroid, matching Python's ordered `min` behavior.

The source's `shift_point` helper keeps a candidate unchanged if its window is
empty. Under this wrapper, candidates start at input points and later become
means of nonempty windows; the empty-window fallback is preserved in the
oracle, although it is unreachable for valid inputs with the Euclidean
bandwidth and threshold-margin rules above.

Success returns `point_count` and writes one exact integer label per input
point as a binary64 value. Malformed, nonfinite, out-of-range, or
threshold-margin-invalid input returns `-1` before output checks. A valid input
with a null output pointer or capacity below `point_count` returns `-2`; errors
write nothing. The independent reference implementation is
[`benchmarks/mean_shift_oracle.py`](../../mean_shift_oracle.py), and the
reviewed workload is in [`workload.json`](workload.json).

## Source

The source is pinned to TheAlgorithms/Python commit
`e1a2a8b016001309a73d5fec4818c35cca139795`, path
`machine_learning/mean_shift.py`, symbol `mean_shift`.

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm mean_shift --language rust
python3 benchmarks/run_float64_slice_io.py --algorithm mean_shift
python3 benchmarks/verify_float64_slice_io.py --algorithm mean_shift --languages rust
~~~

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/mean_shift.c`](../../../c/m/mean_shift.c) |
| C3 | [`c3/m/mean_shift.c3`](../../../c3/m/mean_shift.c3) |
| C++ | [`cpp/m/mean_shift.cpp`](../../../cpp/m/mean_shift.cpp) |
| Elisa | [`elisa/m/mean_shift.elisa`](../../../elisa/m/mean_shift.elisa) |
| Odin | [`odin/m/mean_shift.odin`](../../../odin/m/mean_shift.odin) |
| Nim | [`nim/m/mean_shift.nim`](../../../nim/m/mean_shift.nim) |
| Rust | [`rust/m/mean_shift.rs`](../../../rust/m/mean_shift.rs) |
| V | [`v/m/mean_shift.v`](../../../v/m/mean_shift.v) |
| Zig | [`zig/m/mean_shift.zig`](../../../zig/m/mean_shift.zig) |
