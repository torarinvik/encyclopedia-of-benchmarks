# Order of magnitude conversion

Converts a length between metric units whose sizes are powers of one thousand. The source converts by multiplying the input by a power of ten.

## Contract

- Uses the `float64_triple` ABI: `order_of_magnitude_conversion(value, from_unit_code, to_unit_code)`.
- Unit codes are `0=meter`, `1=kilometer`, `2=megameter`, `3=gigameter`, `4=terameter`, `5=petameter`, `6=exameter`, `7=zettameter`, and `8=yottameter`.
- Each value must be finite and in `[-1e100, 1e100]`. With the largest unit gap of 24 decimal powers, every valid result has magnitude at most `1e124`, within binary64 range.
- Return `value * 10^(from_exponent - to_exponent)`, with exponents `0, 3, 6, ..., 24`. The ports keep the source operation order: compute the power, then multiply the input by it.
- Return `-1.0` for a non-finite/out-of-range value or a unit code outside the integral range 0 through 8. This invalid sentinel can also be a valid result, such as `[-1.0, meter, meter]`; callers distinguish it from invalidity using the input domain.
- Finite results are compared with input-scaled tolerance `1e-12`.

## Source semantics

This package follows the pinned [TheAlgorithms Rust `order_of_magnitude_conversion.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/conversions/order_of_magnitude_conversion.rs). Its `MetricLengthUnit` enum assigns exponents from meter (0) through yottameter (24) in steps of three, and `convert_metric_length` evaluates `value * 10_f64.powi(from_exp - to_exp)`. The source's string wrapper accepts full names and symbols, case-insensitively and with plural forms, and returns an error for invalid names. The benchmark encodes the enum variants as numeric codes so all ports use the same ABI; invalid codes map to the sentinel above because the enum-based source function itself only accepts valid variants.

The separately cataloged `length_conversion` candidate uses a different set of eight units, including imperial units, and converts through meter multipliers. This benchmark covers the nine SI prefixes and the source's direct power-of-ten formula only.

## Workload and build

[`workload.json`](workload.json) covers conversion in both directions, the smallest and largest prefix gaps, negative and zero values, same-unit conversion, and the input limits. Build with the `float64_triple` ABI and record results using `benchmarks/run_float64_triple.py`:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm order_of_magnitude_conversion --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/o/order_of_magnitude_conversion/rust/build.json
```

The nine implementations are in `c/o/order_of_magnitude_conversion.c`, `c3/o/order_of_magnitude_conversion.c3`, `cpp/o/order_of_magnitude_conversion.cpp`, `elisa/o/order_of_magnitude_conversion.elisa`, `nim/o/order_of_magnitude_conversion.nim`, `odin/o/order_of_magnitude_conversion.odin`, `rust/o/order_of_magnitude_conversion.rs`, `v/o/order_of_magnitude_conversion.v`, and `zig/o/order_of_magnitude_conversion.zig`.
