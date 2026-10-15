# Electric power

Computes one missing quantity from the electrical power relation, following the pinned Python implementation.

## Contract

- Uses the `float64_triple` ABI with inputs `[voltage, current, power]` and a binary64 result.
- `voltage` and `current` must be integer-valued finite numbers in `[-10,000, 10,000]`. `power` must be an integer-valued finite number in `[0, 100,000,000]`.
- Exactly one of the three inputs must equal zero. Negative voltage and current are allowed; negative power is rejected.
- If voltage is zero, returns `power / current`; if current is zero, returns `power / voltage`; if power is zero, returns `abs(voltage * current)`.
- The source applies `round(abs(voltage * current), 2)` in the power-zero branch. On this integer-valued bounded domain the product is already an exact integer, so rounding to two decimal places is the identity.
- Invalid inputs return `-1e300`, an ABI sentinel outside the valid output range. Valid source results may equal `-1.0` (for example, voltage zero with current `-1` and power `1`). A valid division can also produce `-1.0`, for example `[0, -1, 1]`; the runner determines validity from the input constraints before comparing the formula result. The source returns a named tuple identifying the solved quantity; that name is determined by the unique zero input, so the scalar ABI returns only its numeric value.
- The workload compares binary64 results with input-scaled tolerance `1e-12`.

## Source semantics

This package follows the pinned [TheAlgorithms Python `electric_power.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/electric_power.py). The function requires exactly one zero, rejects negative power, then branches in voltage/current/power order. Voltage and current retain their signs in the division branches. The benchmark bounds make all accepted operations finite and keep the product branch exact.

## Workload

[`workload.json`](workload.json) covers each solved quantity, signed voltage/current, invalid zero counts, negative power, fractional inputs, and limits. Build with the `float64_triple` ABI and record with `benchmarks/run_float64_triple.py`.
