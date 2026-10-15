# Photoelectric effect

Compute the maximum kinetic energy of an emitted electron from photon frequency and material work function, following the eV branch of the pinned Python implementation.

## Contract

- The `i64_array_float64` ABI accepts `[frequency_hz, work_function_ev]` and returns binary64 electron energy in electronvolts.
- Frequency is an integer in `[0, 10^18]` Hz. Work function is an integer in `[0, 1,000]` eV. The source accepts floating-point values and negative work functions, but this benchmark uses a bounded nonnegative integer subset.
- The `in_ev` option is fixed to `true`; the joule branch is outside this package.
- The result follows the source operation order: first form `h_ev = 4.1357 * pow(10, -15)`, then return `max((h_ev * frequency_hz) - work_function_ev, 0)`. Zero is returned when photon energy does not exceed the work function.
- Invalid length or out-of-domain inputs return `-1e300`. Valid results use relative and absolute tolerances of `1e-12`.

## Source semantics

This follows the pinned [TheAlgorithms Python `photoelectric_effect.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/photoelectric_effect.py). The source function is named `maximum_kinetic_energy`; it rejects negative frequency and clamps a negative energy difference to zero. This benchmark fixes `in_ev=True` and uses integer-valued frequency and work-function inputs.

## Workload

[`workload.json`](workload.json) covers the pinned positive-energy example, the clamp at zero, zero frequency/work function, large bounded frequency, and invalid input cases.
