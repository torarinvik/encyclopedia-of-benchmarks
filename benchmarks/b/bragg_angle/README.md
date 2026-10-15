# Bragg Angle

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/bragg_angle.py). It computes `sine = (order * wavelength) / (2 * distance)`, rejects sine values outside [-1, 1], then rounds the angle to one decimal place.

The `i64_array_float64` ABI accepts exactly `[distance_pm, order, wavelength_pm]`. The two length fields are integer picometres; their common unit cancels in the ratio. Distance is bounded to 1..1,000,000 pm, order to -1,000..1,000, and wavelength to 0..1,000,000 pm. Order is signed, while wavelength is restricted to a nonnegative subset of the source's domain; zero order and zero wavelength are supported, but zero or negative distance is excluded. Ports preserve the sine expression order and apply the normalized benchmark rounding rule: round `degrees * 10` to the nearest integer using ties-to-even, then divide by 10. This explicit rule is shared across the ports; it is not a promise to reproduce Python's `round(theta_degrees, 1)` bit-for-bit for every binary64 value near a decimal midpoint. Invalid length, out-of-domain values, or a sine outside [-1, 1] return -1e300.

The output is the Bragg angle in degrees. Relative and absolute output tolerances are 1e-12. Runtime and auxiliary space are O(1).
