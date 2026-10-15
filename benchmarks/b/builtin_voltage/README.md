# Built-in voltage

Compute the built-in voltage of a pn junction from donor, acceptor, and intrinsic carrier concentrations, following the pinned Python implementation.

## Contract

- The `i64_array_float64` ABI accepts `[donor_conc, acceptor_conc, intrinsic_conc]` and returns a binary64 voltage in volts.
- Each concentration is an integer from 1 through 1,000. Both donor and acceptor concentrations must be strictly greater than intrinsic concentration.
- Temperature is fixed at the source value, `T = 300 K`. The result preserves source operation order: `Boltzmann * 300 * log((donor_conc * acceptor_conc) / (intrinsic_conc ** 2)) / electron_volt`.
- The source uses SciPy's pinned SI constants: Boltzmann constant `1.380649e-23` and electron volt `1.602176634e-19` joules. The positive integer domain bounds all intermediate products and keeps the logarithm argument positive.
- Invalid length or concentration constraints return `-1e300`. Valid binary64 results use relative and absolute tolerances of `1e-12`.

## Source semantics

This follows the pinned [TheAlgorithms Python `builtin_voltage.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/builtin_voltage.py). The source fixes temperature to 300 K, checks positivity before requiring donor and acceptor concentrations to exceed intrinsic concentration, and divides the thermal logarithm by the electron volt constant to return volts. The benchmark uses a bounded integer-valued subset of its floating-point inputs.

## Workload

[`workload.json`](workload.json) covers several valid concentration ratios, the strict donor and acceptor conditions, and invalid zero, negative, and out-of-range inputs.
