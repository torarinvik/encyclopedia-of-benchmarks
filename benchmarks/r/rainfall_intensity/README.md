# Rainfall intensity

Compute rainfall intensity from duration and return period using the Sherman intensity-duration-frequency curve in the pinned Python source.

## Contract

- The `i64_array_float64` ABI accepts `[coefficient_k, coefficient_a, coefficient_b, coefficient_c, return_period, duration]` and returns binary64 intensity in millimetres per hour.
- All six inputs are positive integers with bounds: `k` 1..1,000, `a` 1..3, `b` 1..100, `c` 1..3, return period 1..100 years, and duration 1..1,000 minutes. This is a bounded discrete subset of the source's positive floating-point inputs.
- The result preserves the source expression order: `(k * return_period**a) / ((duration + b)**c)`.
- Invalid length or values return `-1e300`. Valid outputs use relative and absolute tolerances of `1e-12`.

## Source semantics

This package follows the pinned [TheAlgorithms Python `rainfall_intensity.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/rainfall_intensity.py), which implements the Sherman intensity-duration-frequency curve and rejects any nonpositive parameter. The benchmark bounds keep both powers finite and the denominator positive.

## Workload

[`workload.json`](workload.json) covers several exponent combinations, the maximum intensity within the bounds, a small positive result, and invalid length or nonpositive/out-of-range inputs.
