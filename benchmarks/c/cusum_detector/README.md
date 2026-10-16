# CUSUM detector

This benchmark measures the pinned Java detector's `scan` operation over a bounded stream. For each sample, it computes normalized evidence and updates the upper and lower one-sided sums:

```text
z = (sample - target) / sigma
upper = max(0, upper + z - allowance)
lower = max(0, lower - z - allowance)
```

It reports upward when `upper > threshold`, otherwise downward when `lower > threshold`, otherwise no signal. The comparisons are strict and the upward branch is checked first. After either alarm, the detector clears both sums before reading the next sample.

## Contract

- Pack signed 64-bit integers as `[n, target, sigma, allowance, threshold, samples...]`, with exactly `n + 5` values.
- `n` is in `0..=128`; `target` and each sample are in `[-1000, 1000]`; `sigma` and `threshold` are in `[1, 1000]`; `allowance` is in `[0, 1000]`. Values are expressed in integer units.
- Emit one signed 64-bit little-endian signal per sample: `0` for `NONE`, `1` for `UPWARD`, and `-1` for `DOWNWARD`. Empty scans return zero bytes.
- Malformed packing or out-of-domain values return `-1`. The output workspace is 1,024 bytes. Capacity below `8*n` returns `-2`.

The input restrictions keep every value finite and make the encoded sample units exactly representable as binary64. Workload cases stay away from floating-point threshold boundaries except for the exact strict-boundary example with `sigma=1`, whose accumulated values are integers.

## Source

- [TheAlgorithms/Java `CusumDetector.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/CusumDetector.java), commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.
- Signal codes correspond to the companion [`ShiftSignal.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/streaming/ShiftSignal.java), with the benchmark's explicit integer encoding above.

This is the stateful two-sided CUSUM scan. It is distinct from EWMA change detection, which uses an exponentially weighted running average. See [`workload.json`](workload.json) for upward and downward alarms, reset behavior, a strict-threshold boundary, empty input, malformed values, and the capacity sentinel.

Verify all nine ports against the source-ordered oracle with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm cusum_detector
```
