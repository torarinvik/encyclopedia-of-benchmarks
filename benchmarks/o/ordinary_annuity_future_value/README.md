# Ordinary annuity future value

## Contract

Compute the future value of equal payments made at the end of each term. The
three binary64 inputs are `[term_payment, number_of_payments, term_interest_rate]`.
Payment is in `[0, 10,000]`, number of payments is an integer in `[1, 20]`, and
the per-term rate is in `[0.01, 0.5]`. Return a binary64 result; malformed or
out-of-domain inputs map to `-1e300`.

The calculation preserves the pinned Python operation order:

```text
term_payment * ((((1 + term_interest_rate) ** number_of_payments) - 1) / term_interest_rate)
```

The domain excludes a zero rate because the source divides by the rate. Results
are compared with absolute and relative tolerance `1e-12` to allow ordinary
binary64 power-library differences.

## Source and distinction

The contract follows TheAlgorithms Python
[`ordinary_annuity_future_value.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/ordinary_annuity_future_value.py)
at commit `e1a2a8b016001309a73d5fec4818c35cca139795`. Its ordinary annuity pays
at the end of each term and returns `payment * annuity_factor`. The separately
benchmarked `annuity_due_future_value` multiplies that amount by `(1 + rate)`
because its payments occur at the beginning of each term.

[`workload.json`](workload.json) contains the bounded sample cases. The nine
ports use the shared `float64_triple` ABI.

The shared `run_float64_triple.py` runner checks each expected value against
the pinned operation order and applies the workload's absolute and relative
tolerances before timing.

## Implementations

The source files are `c/o/ordinary_annuity_future_value.c`,
`c3/o/ordinary_annuity_future_value.c3`,
`cpp/o/ordinary_annuity_future_value.cpp`,
`elisa/o/ordinary_annuity_future_value.elisa`,
`nim/o/ordinary_annuity_future_value.nim`,
`odin/o/ordinary_annuity_future_value.odin`,
`rust/o/ordinary_annuity_future_value.rs`,
`v/o/ordinary_annuity_future_value.v`, and
`zig/o/ordinary_annuity_future_value.zig`.
