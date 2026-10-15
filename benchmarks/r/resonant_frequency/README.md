# Resonant frequency

Compute the resonant frequency of an LC circuit from its inductance and capacitance, following the pinned Python implementation.

## Contract

- The `i64_array_float64` ABI accepts `[inductance_henries, capacitance_farads]` and returns a binary64 frequency in hertz.
- Both inputs must be integer-valued magnitudes in the normalized range 1 through 1,000. This positive discrete domain follows the source's guard against zero and negative values.
- The result preserves the source formula and operation order: `1 / (2 * pi * sqrt(inductance * capacitance))`.
- Invalid length or values return `-1e300`. Valid outputs use relative and absolute tolerances of `1e-12`.

## Source semantics

This package follows the pinned [TheAlgorithms Python `resonant_frequency.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/resonant_frequency.py). It returns the numeric result paired with the label “Resonant frequency”; this scalar ABI keeps that numeric value. The benchmark fixes positive integer-valued henries and farads as a bounded portable subset of the source's floating-point inputs.

## Workload

[`workload.json`](workload.json) includes the pinned example, lower and upper input bounds, a mixed product, and invalid zero, negative, out-of-range, and wrong-length inputs.
