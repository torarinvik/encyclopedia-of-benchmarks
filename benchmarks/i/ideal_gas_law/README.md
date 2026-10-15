# Ideal Gas Law

This package benchmarks all four public calculations in the pinned [TheAlgorithms/Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/ideal_gas_law.py). Each operation uses the source function's argument order and formula, with the universal gas constant `R = 8.314462`:

| Selector | Source function | Arguments after selector | Formula | Output |
| --- | --- | --- | --- | --- |
| `0` | `pressure_of_gas_system(moles, kelvin, volume)` | `[moles, kelvin, volume]` | `moles * kelvin * R / volume` | pressure |
| `1` | `volume_of_gas_system(moles, kelvin, pressure)` | `[moles, kelvin, pressure]` | `moles * kelvin * R / pressure` | volume |
| `2` | `temperature_of_gas_system(moles, volume, pressure)` | `[moles, volume, pressure]` | `pressure * volume / (moles * R)` | temperature |
| `3` | `moles_of_gas_system(kelvin, volume, pressure)` | `[kelvin, volume, pressure]` | `pressure * volume / (kelvin * R)` | amount of substance |

The `i64_array_float64` ABI accepts exactly four signed integers: `[operation, arg1, arg2, arg3]`. The selector must be 0..3 and each argument must be 0..1,000. For operations 0 and 1, `arg3` is the denominator and must be nonzero. For operations 2 and 3, `arg1` is the denominator and must be nonzero. Zero remains valid in every other position, matching the source's nonnegative-input domain. These bounds choose a finite-output integer subset of the source's floating-point API. Invalid ABI inputs return `-1e300`; the Python source raises on negative inputs and on a zero denominator.

The output is a binary64 result in the unit implied by the selected source function. Runtime and auxiliary space are O(1).
