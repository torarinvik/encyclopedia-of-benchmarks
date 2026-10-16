# Depreciation schedules

This package ports the five public schedule methods in the pinned Rust `financial/depreciation.rs`: straight-line, diminishing balance, units-of-production, sum-of-years' digits, and double-declining balance. The benchmark entrypoint selects one method per call.

## Contract

Input is a signed 64-bit integer array, with all monetary values encoded in micro-units (divide by 1,000,000 to get the source `f64` value):

- `[0, years, purchase_micro, residual_micro]`: straight-line.
- `[1, years, purchase_micro, residual_micro, rate_ppm]`: diminishing balance, where `rate_ppm / 1,000,000` is the source rate.
- `[2, purchase_micro, residual_micro, total_units, units_per_period...]`: units-of-production; the number of period entries supplies `years`.
- `[3, years, purchase_micro, residual_micro]`: sum-of-years' digits.
- `[4, years, purchase_micro, residual_micro]`: double-declining balance.

The bounded domain is 1–16 years, purchase value from 0 through 1,000,000, residual value from -1,000,000 through purchase value, diminishing rate from 0.000001 through 1, and units/period estimates with absolute value at most 1,000,000,000. Units-of-production requires positive total units and preserves the Rust source's relative mismatch tolerance of `1e-6 * total_units`; estimated period units may be negative because the source does not reject them. The restricted integer scaling removes non-finite floating-point inputs while retaining representative fractional values.

Malformed input returns `-1` and no output. Success writes the full annual expense schedule as little-endian IEEE-754 binary64 values and returns its byte length. A valid schedule with insufficient output capacity returns `-2` without writing. Maximum output is 128 bytes. Output comparison uses absolute tolerance `1e-9` and relative tolerance `1e-12`.

## Workload and oracle

[`workload.json`](workload.json) covers all five methods, residual values, source rounding remainders, units tolerance, and invalid/capacity cases. The independent oracle is [`depreciation_oracle.py`](../../depreciation_oracle.py).

Pinned source: [TheAlgorithms/Rust `src/financial/depreciation.rs`](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/financial/depreciation.rs).

## Running and verifying

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm depreciation --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/depreciation/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm depreciation --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/depreciation.c`](../../../c/d/depreciation.c) |
| C3 | [`c3/d/depreciation.c3`](../../../c3/d/depreciation.c3) |
| C++ | [`cpp/d/depreciation.cpp`](../../../cpp/d/depreciation.cpp) |
| Elisa | [`elisa/d/depreciation.elisa`](../../../elisa/d/depreciation.elisa) |
| Nim | [`nim/d/depreciation.nim`](../../../nim/d/depreciation.nim) |
| Odin | [`odin/d/depreciation.odin`](../../../odin/d/depreciation.odin) |
| Rust | [`rust/d/depreciation.rs`](../../../rust/d/depreciation.rs) |
| V | [`v/d/depreciation.v`](../../../v/d/depreciation.v) |
| Zig | [`zig/d/depreciation.zig`](../../../zig/d/depreciation.zig) |
