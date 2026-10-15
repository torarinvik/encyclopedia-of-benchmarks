# Equated monthly installments

Compute the monthly payment for a loan from its principal, annual interest rate, and repayment term in years.

## Contract

- The three binary64 inputs are `(principal, rate_per_annum, years_to_repay)`, in that order.
- Accept principal in `(0, 1,000,000]`, annual decimal rate in `[0.0001, 0.2]`, and an integral term in years from 1 through 30.
- Convert the annual rate to monthly rate `r = rate_per_annum / 12` and years to `n = years_to_repay * 12` monthly payments. Return `principal * r * (1+r)^n / ((1+r)^n - 1)` using binary64 arithmetic.
- Return `-1e300` for inputs outside the benchmark domain. The Python source errors for nonpositive principal, negative rate, or nonpositive/nonintegral term. Rust reports errors for nonpositive principal, negative rate, or zero years, and handles zero rate with `principal / n`; Python's formula divides by zero at a zero rate. The benchmark uses positive rates, so both sources agree on the measured domain.
- Python evaluates the power in both numerator and denominator; Rust computes it once and reuses it. The ports share the formula and operation order and the workload allows a relative input-scaled tolerance of `1e-10` for library power differences.
- The computation takes `O(1)` time and `O(1)` auxiliary space.

## Sources

- [Python `equated_monthly_installments.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/equated_monthly_installments.py)
- [Rust `equated_monthly_installments.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/equated_monthly_installments.rs)

## Workload and build

[`workload.json`](workload.json) covers both pinned examples, a low positive rate, the maximum term and rate, and invalid principal, rate, or term values. All nine ports use the `float64_triple` ABI.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm equated_monthly_installments --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/e/equated_monthly_installments/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/e/equated_monthly_installments.c`](../../../c/e/equated_monthly_installments.c) |
| C3 | [`c3/e/equated_monthly_installments.c3`](../../../c3/e/equated_monthly_installments.c3) |
| C++ | [`cpp/e/equated_monthly_installments.cpp`](../../../cpp/e/equated_monthly_installments.cpp) |
| Elisa | [`elisa/e/equated_monthly_installments.elisa`](../../../elisa/e/equated_monthly_installments.elisa) |
| Nim | [`nim/e/equated_monthly_installments.nim`](../../../nim/e/equated_monthly_installments.nim) |
| Odin | [`odin/e/equated_monthly_installments.odin`](../../../odin/e/equated_monthly_installments.odin) |
| Rust | [`rust/e/equated_monthly_installments.rs`](../../../rust/e/equated_monthly_installments.rs) |
| V | [`v/e/equated_monthly_installments.v`](../../../v/e/equated_monthly_installments.v) |
| Zig | [`zig/e/equated_monthly_installments.zig`](../../../zig/e/equated_monthly_installments.zig) |
