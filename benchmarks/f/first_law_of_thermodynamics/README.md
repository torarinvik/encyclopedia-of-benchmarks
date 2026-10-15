# First law of thermodynamics

Compute one of the three related quantities from the first law, following the numeric formulas in the pinned Python source.

## Contract

- The `float64_triple` ABI receives `[operation, a, b]`. Operation must be the integer-valued selector `0`, `1`, or `2`; `a` and `b` must be finite integer-valued binary64 numbers in `[-1,000,000, 1,000,000]`.
- Selector `0` computes work `Q - ΔU`; selector `1` computes heat `ΔU + W`; selector `2` computes internal-energy variation `Q - W`.
- Each source operation rounds its result to one decimal place. With integer-valued inputs in this bounded range, each result is an integer, so source rounding leaves the value unchanged and has no decimal tie cases.
- Invalid selectors or values return `-1e300`. Valid binary64 output uses relative and absolute tolerances of `1e-12`.
- The Python functions also print system-state descriptions. Those print side effects are outside the numeric ABI and are not part of the returned result.

## Source semantics

The package follows the three formulas in [TheAlgorithms Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/first_law_of_thermodynamics.py). The input names are `Q` (heat), `ΔU` (internal-energy variation), and `W` (work); all values use the same energy unit.

## Workload

[`workload.json`](workload.json) exercises all selector branches, positive and negative values, zero, invalid selectors, fractional inputs, and out-of-range inputs. The runner uses `float64_triple`.
