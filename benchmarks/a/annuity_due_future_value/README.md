# Annuity due future value

Computes the future value of equal payments made at the beginning of each period, following the pinned Python source formula.

## Contract

- Uses the three-input binary64 ABI: `double annuity_due_future_value(double payment, double periods, double rate)`.
- The inputs are payment amount, an integral payment count, and per-period interest rate, in that order. The ABI carries all three as binary64 values.
- The bounded domain is payment in `[0, 10000]`, periods in `[1, 20]` (integral), and rate in `(0, 0.5]`.
- Return `payment * ((((1 + rate) ** periods) - 1) / rate) * (1 + rate)`, evaluating the annuity factor first and multiplying by payment and then `(1 + rate)`.
- Rate zero is outside the domain because the source divides by it. The source formula accepts negative nonzero rates and does not validate period counts; the bounded workload excludes both cases.
- Compare using input-scaled tolerance `1e-9`; the recorder scales by `max(1, abs(payment), abs(periods))`.

## Source semantics

The benchmark follows the executable formula in the pinned [TheAlgorithms Python `annuity_due_future_value.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/annuity_due_future_value.py). The source computes `(((1 + rate) ** number_of_payments) - 1) / rate`, then multiplies by payment and by `(1 + rate)`. It has no explicit validation; a zero rate raises division by zero. Ports preserve the formula and operation order over the documented domain.

## Workload and build

[`workload.json`](workload.json) covers zero and positive payments, short and long payment counts, and rates near both ends of the supported range. Build with the `float64_triple` ABI family and record with `benchmarks/run_float64_triple.py`:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm annuity_due_future_value --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/a/annuity_due_future_value/rust/build.json
```

The nine implementations are in `c/a/annuity_due_future_value.c`, `c3/a/annuity_due_future_value.c3`, `cpp/a/annuity_due_future_value.cpp`, `elisa/a/annuity_due_future_value.elisa`, `nim/a/annuity_due_future_value.nim`, `odin/a/annuity_due_future_value.odin`, `rust/a/annuity_due_future_value.rs`, `v/a/annuity_due_future_value.v`, and `zig/a/annuity_due_future_value.zig`.
