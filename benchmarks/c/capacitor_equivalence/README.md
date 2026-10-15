# Capacitor equivalence

Compute equivalent capacitance for capacitors connected in parallel or in series, following the pinned Python implementation.

## Contract

- The `i64_array_float64` ABI accepts `[operation, capacitor_1, ..., capacitor_n]` and returns a binary64 result. There must be 1..32 capacitor values after the operation selector.
- Operation 0 computes parallel capacitance by adding values sequentially; each value may be an integer from 0 through 1,000. Operation 1 computes series capacitance by adding reciprocals sequentially and taking the reciprocal of the total; each value must be an integer from 1 through 1,000.
- Integer-valued normalized capacitance inputs are used so the workload is bounded and portable. The output is expressed in the same capacitance unit as the inputs.
- Invalid length, operation, or mode-specific values return `-1e300`. Valid outputs use relative and absolute tolerances of `1e-12`.

## Source semantics

This follows the pinned [TheAlgorithms Python `capacitor_equivalence.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/capacitor_equivalence.py). Its parallel function sums each capacitance in order and permits zero values. Its series function adds `1 / capacitor` in order, rejects zero and negative values, then returns the reciprocal. The source docstring has a resistance wording typo, but the formulas implement capacitance.

This is a distinct circuit contract from [`resistor_equivalence`](../r/resistor_equivalence/README.md): parallel capacitors add while parallel resistors add reciprocals; series capacitors add reciprocals while series resistors add directly.

## Workload

[`workload.json`](workload.json) covers both connection modes, zero in parallel, singleton inputs, the bounds, and invalid operation, length, and value cases.
