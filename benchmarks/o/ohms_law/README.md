# Ohm's law

Solve one missing quantity in the electrical relation `V = I * R`, following the pinned Python implementation.

## Contract

- The `float64_triple` ABI receives `[voltage_V, current_A, resistance_ohms]` and returns the solved numeric value as binary64.
- Exactly one input must be zero. Voltage and current must be integer-valued finite numbers in `[-1000, 1000]`; resistance must be an integer-valued finite number in `[0, 1000]`. The nonzero supplied values may be negative for voltage or current, but resistance cannot be negative.
- Preserve the source branch order: if voltage is zero, return `current * resistance`; otherwise, if current is zero, return `voltage / resistance`; otherwise resistance is zero, and return `voltage / current`.
- The output unit is determined by the missing input: volts, amperes, or ohms. This bounded integer-valued domain is a normalized subset of the source's numeric inputs.
- Invalid layouts or values return `-1e300`. Valid binary64 results use relative and absolute tolerances of `1e-12`.

## Source semantics

The pinned [TheAlgorithms Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/ohms_law.py) requires exactly one missing value and computes that value by the corresponding branch. The Ruby candidate differs: it only computes voltage from positive current and resistance and returns a formatted string, so the benchmark follows the Python numeric API.

## Workload

[`workload.json`](workload.json) covers each solved quantity, signed voltage/current, bounds, and invalid zero counts, negative resistance, fractions, and out-of-range values. The runner uses `float64_triple`.
