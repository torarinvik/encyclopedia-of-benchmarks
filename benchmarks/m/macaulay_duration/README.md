# Macaulay duration

Compute the bond's present-value-weighted average cash-flow time using the pinned Python implementation's annual coupon and yield inputs.

## Contract

- Input is `[face_value_micro, coupon_rate_micro, periods, yield_rate_micro]` in a signed 64-bit array. Divide face value, coupon rate, and yield rate by 1,000,000; `periods` is an integer number of years (one cash-flow period per year).
- Face value is `0.000001..1,000,000`, coupon rate is `0..1`, yield rate is `0.000001..1`, and periods are `1..64`.
- The packed input must contain exactly four values. Inputs outside the domain or a null pointer return `-1e300`; the pinned source raises for nonpositive face value, negative coupon, nonpositive periods, or nonpositive yield.
- For each period, cash flow is `face_value * coupon_rate`, plus face value at maturity. The implementation separately discounts the period-weighted cash flow and cash flow using `(1 + yield_rate) ** period`, accumulates each total in period order, and divides weighted total by present-value total.
- Return Macaulay duration in years as binary64. Valid results are finite and lie in `[1, periods]`; absolute and relative tolerance are `1e-12`.

## Workload and oracle

[`workload.json`](workload.json) covers the three source examples, zero-coupon and one-period bonds, coupon/yield relationships, rate bounds, and malformed inputs. The independent oracle is [`macaulay_duration_oracle.py`](../../macaulay_duration_oracle.py).

## Reviewed source

[TheAlgorithms/Python `financial/macaulay_duration.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/macaulay_duration.py)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm macaulay_duration --language rust
python3 benchmarks/run_i64_array_float64.py --algorithm macaulay_duration
python3 benchmarks/verify_i64_array_float64.py --algorithm macaulay_duration
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/m/macaulay_duration.c`](../../../c/m/macaulay_duration.c) |
| C3 | [`c3/m/macaulay_duration.c3`](../../../c3/m/macaulay_duration.c3) |
| C++ | [`cpp/m/macaulay_duration.cpp`](../../../cpp/m/macaulay_duration.cpp) |
| Elisa | [`elisa/m/macaulay_duration.elisa`](../../../elisa/m/macaulay_duration.elisa) |
| Nim | [`nim/m/macaulay_duration.nim`](../../../nim/m/macaulay_duration.nim) |
| Odin | [`odin/m/macaulay_duration.odin`](../../../odin/m/macaulay_duration.odin) |
| Rust | [`rust/m/macaulay_duration.rs`](../../../rust/m/macaulay_duration.rs) |
| V | [`v/m/macaulay_duration.v`](../../../v/m/macaulay_duration.v) |
| Zig | [`zig/m/macaulay_duration.zig`](../../../zig/m/macaulay_duration.zig) |
