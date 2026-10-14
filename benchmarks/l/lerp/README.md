# Linear interpolation

This benchmark evaluates a point between two finite binary64 endpoints. It is grouped by the algorithm name under the `l/` folder.

## Contract

- `start` and `end` are finite binary64 values in `[-10^12, 10^12]`.
- `t` is finite and in `[0, 1]`.
- The result is `start + t * (end - start)` in binary64.
- Results are compared with absolute error at most `1e-12 * max(1, |start|, |end|)`, which accounts for rounding relative to the input scale when endpoints nearly cancel.

The C reference uses the selected expression while the Go reference uses the algebraically equivalent `(1 - t) * start + t * end`. The contract chooses the C expression and uses tolerance for the rounding differences inherent in binary floating-point arithmetic. All local ports use binary64 and generic compiler settings.

## Workload

`workload.json` covers endpoints, midpoint and fractional interpolation, negative and descending endpoints, identical values, large magnitudes, and values near zero. The verifier adds a deterministic grid and random finite inputs. Its oracle evaluates the mathematical expression at high precision over the exact binary64 inputs, then rounds to binary64.

## Run

Use the `float64_triple` ABI family. `benchmarks/verify_float64_triple.py` checks each implementation against the high-precision oracle and records one-sample correctness results.
