# Integration by Simpson approximation

This benchmark ports the pinned Python `simpson_integration` routine with its fixed `f(x)=x²` and `N_STEPS=1000`. Input is `[lower, upper, precision]`; integer endpoints are bounded to -10 through 10 with `lower < upper`, and decimal precision is 0 through 4.

The implementation evaluates endpoint weights 1, interior odd-index weights 4, and interior even-index weights 2 in source order, multiplies by `h/3`, then rounds to the requested decimal places using ties-to-even. Invalid input returns `-1e300`; valid output is binary64 with absolute tolerance 1e-12. See the [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/integration_by_simpson_approx.py).
