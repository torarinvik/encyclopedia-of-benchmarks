# Inductive reactance

Solve one missing quantity in the inductive reactance relation, following the pinned Python implementation.

## Contract

- The `i64_array_float64` ABI accepts exactly `[inductance_henries, frequency_hertz, reactance_ohms]` and returns a binary64 result.
- Exactly one input must be zero. The other two inputs must be integers from 1 through 1,000. Negative values and values outside this normalized discrete domain are invalid.
- The function preserves the source branch order and expressions: if inductance is zero, return `reactance / (2 * pi * frequency)`; if frequency is zero, return `reactance / (2 * pi * inductance)`; otherwise reactance is zero and return `2 * pi * frequency * inductance`.
- The result's unit depends on the zero position: henries, hertz, or ohms. The source returns a dictionary naming the solved quantity; the unique zero position determines that name, so this scalar ABI retains the numeric value.
- Invalid input returns `-1e300`. Valid binary64 results use relative and absolute tolerances of `1e-12`.

## Source semantics

This package follows the pinned [TheAlgorithms Python `ind_reactance.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/ind_reactance.py). The source requires exactly one zero, rejects negative values, and uses `2 * pi * frequency * inductance` for inductive reactance. The benchmark restricts the source's nonnegative floating-point inputs to bounded integer-valued magnitudes for a portable workload.

## Workload

[`workload.json`](workload.json) covers all three solved quantities, lower and upper values, and invalid zero counts, negative values, and out-of-range values.
