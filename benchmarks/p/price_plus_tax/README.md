# Price plus tax

Compute the total price of a good or service using the pinned Python formula `price * (1 + tax_rate)`. This benchmark preserves the formula's binary64 result without rounding it to a currency unit.

## Contract

- Input is a signed 64-bit array `[price_micro, tax_rate_micro]`; divide both values by 1,000,000 to obtain the source function's `price` and `tax_rate` floats.
- Price is bounded to `$0` through `$1,000,000` (`0..1,000,000,000,000` micro-units). Tax rate is bounded to `0.0..1.0` (`0..1,000,000` micro-units).
- The packed input must contain exactly two values. Empty, short, long, out-of-range, or null input returns `-1e300`.
- Return `price * (1 + tax_rate)` as binary64 with no currency rounding.
- Absolute and relative tolerance are `1e-12`.

## Workload and oracle

[`workload.json`](workload.json) covers zero and fractional values, both examples from the source documentation, maximum bounds, and malformed input. The independent oracle is [`price_plus_tax_oracle.py`](../../price_plus_tax_oracle.py).

## Reviewed source

[TheAlgorithms/Python `financial/price_plus_tax.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/price_plus_tax.py)

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm price_plus_tax --language rust
python3 benchmarks/run_i64_array_float64.py --algorithm price_plus_tax
python3 benchmarks/verify_i64_array_float64.py --algorithm price_plus_tax
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/price_plus_tax.c`](../../../c/p/price_plus_tax.c) |
| C3 | [`c3/p/price_plus_tax.c3`](../../../c3/p/price_plus_tax.c3) |
| C++ | [`cpp/p/price_plus_tax.cpp`](../../../cpp/p/price_plus_tax.cpp) |
| Elisa | [`elisa/p/price_plus_tax.elisa`](../../../elisa/p/price_plus_tax.elisa) |
| Nim | [`nim/p/price_plus_tax.nim`](../../../nim/p/price_plus_tax.nim) |
| Odin | [`odin/p/price_plus_tax.odin`](../../../odin/p/price_plus_tax.odin) |
| Rust | [`rust/p/price_plus_tax.rs`](../../../rust/p/price_plus_tax.rs) |
| V | [`v/p/price_plus_tax.v`](../../../v/p/price_plus_tax.v) |
| Zig | [`zig/p/price_plus_tax.zig`](../../../zig/p/price_plus_tax.zig) |
