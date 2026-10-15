# Electric conductivity

Solve conductivity, electron concentration, or electron mobility from the other two quantities using the pinned semiconductor relation.

## Contract

- The `i64_array_float64` ABI accepts `[conductivity, electron_conc, mobility]` and returns the numeric result as binary64.
- Exactly one input must be zero. Each of the other two inputs must be an integer from 1 through 1,000. Negative values, extra zeros, and values outside this normalized discrete domain are invalid.
- The source uses electron charge `1.6021e-19` coulombs and branches in this order: conductivity zero returns `mobility * electron_conc * electron_charge`; electron concentration zero returns `conductivity / (mobility * electron_charge)`; otherwise mobility is `conductivity / (electron_conc * electron_charge)`.
- The output unit depends on the zero position: conductivity (S/m), electron concentration (m⁻³), or mobility (m²/(V·s)).
- Invalid length, zero count, or values return `-1e300`. Valid results use relative tolerance `1e-12` and absolute tolerance `1e-30`.

## Source semantics

This follows the pinned [TheAlgorithms Python `electric_conductivity.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/electric_conductivity.py). It uses `conductivity = electron_conc * mobility * electron_charge`, rejects negative inputs, and returns a name/value pair for the quantity at zero. The scalar benchmark preserves the numeric value; the zero position identifies which quantity was solved. The integer-valued bounds keep products exact before multiplication by the electron-charge constant.

## Workload

[`workload.json`](workload.json) covers all three solved quantities, low and high valid values, zero-count errors, negative values, and values above the bound.
