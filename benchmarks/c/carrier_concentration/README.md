# Carrier Concentration

This package follows the pinned [TheAlgorithms/Python `carrier_concentration`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/carrier_concentration.py). It solves the semiconductor relation by computing whichever one of electron concentration, hole concentration, or intrinsic concentration is missing:

- If electron concentration is zero, return `intrinsic_conc**2 / hole_conc`.
- If hole concentration is zero, return `intrinsic_conc**2 / electron_conc`.
- If intrinsic concentration is zero, return `(electron_conc * hole_conc)**0.5`.

The `i64_array_float64` ABI accepts exactly `[electron_conc, hole_conc, intrinsic_conc]`. Each input is an integer in `0..1,000,000`, and exactly one input must be zero. The scalar result is the missing concentration corresponding to that zero position: index 0 means electron concentration, index 1 means hole concentration, and index 2 means intrinsic concentration. This encodes the source tuple's field label through the input position while retaining its numeric result.

The bounds keep the source squares and products at or below 1,000,000,000,000, which is exactly representable in binary64, and all results finite. The source rejects negative concentrations and any input with other than one zero; malformed or out-of-domain ABI inputs return `-1e300`. The nearby `builtin_voltage` package uses related carrier quantities but computes a logarithmic voltage rather than solving for a missing concentration.

Runtime and auxiliary space are O(1). The workload covers each missing-field branch, fractional quotient output, invalid zero patterns, negative input, and bounds.

The shared float64 runner preserves the source's branch selection and expression order for the missing concentration.
