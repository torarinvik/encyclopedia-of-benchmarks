# Shear stress

Solve one missing quantity in the relation between shear stress, tangential force, and cross-sectional area, following the pinned Python implementation.

## Contract

- The `float64_triple` ABI receives `[stress, tangential_force, area]` and returns the solved numeric value as binary64.
- Exactly one input must be zero. The other two inputs must be integer-valued finite numbers from 1 through 1,000. Negative values, fractions, and values outside this bound are invalid.
- If stress is zero, return `tangential_force / area`. If tangential force is zero, return `stress * area`. Otherwise, area is zero and the result is `tangential_force / stress`. This preserves the source branch and formula order.
- Stress is measured in pascals, force in newtons, and area in square metres. The output's unit is determined by which input is zero; the integer-valued workload is a normalized discrete subset of the source's nonnegative numeric inputs.
- Invalid inputs return `-1.0`. The source returns a tuple naming the solved quantity; the unique zero position determines that name, so the scalar ABI records the numeric value.
- Binary64 results use relative and absolute tolerances of `1e-12`.

## Source semantics

The pinned [TheAlgorithms Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/shear_stress.py) requires exactly one zero, rejects negative values, and solves `stress = tangential_force / area` by the corresponding branch. Unlike [`electric_power`](../../e/electric_power/README.md), this benchmark uses the mechanical stress relation and its three branch formulas.

## Workload

[`workload.json`](workload.json) covers all three solved quantities, the bounds, and invalid zero counts, negative values, fractional values, and out-of-range values. The runner uses `float64_triple`.
