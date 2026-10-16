# Present value (Rust rounding)

Compute the present value of a sequence of yearly cash flows using the pinned Rust implementation. This package preserves Rust's `f64::round` behavior: halfway values round away from zero.

## Contract

- Input is `[count, discount_rate_ppm, cash_flow_0_milli, ...]` in a signed 64-bit array. Decode the rate by dividing by 1,000,000 and each cash flow by 1,000.
- Require 1 through 8 cash flows, a discount rate of either 0 or 1,000,000 ppm (0 or 1), and each cash flow from -1,000,000 through 1,000,000 milli (-1,000 through 1,000) in increments of 125 milli. The packed length must equal `count + 2`; the parser admits up to 11 values to cover an overlong malformed input.
- For each cash flow at index `i`, compute `cash_flow / (1 + discount_rate)^i`, sum in input order, then return `(sum * 100).round() / 100`, with halfway cases away from zero. Index zero is undiscounted.
- Empty, negative-rate, unsupported-rate, malformed, out-of-range, or null-pointer input returns `-1e300`. Valid results are finite and compared with absolute and relative tolerance `1e-12`.

## Workload and source

[`workload.json`](workload.json) covers both supported discount rates, flow boundaries, invalid packed inputs, and positive and negative halfway cases. At rate zero, cash flows `+1.125` and `-1.125` return `+1.13` and `-1.13` respectively. Multiples of 0.125 are binary-exact, and the supported discount factors are powers of two, so only the tie-rounding rule distinguishes the language sources.

This package follows [TheAlgorithms/Rust `financial/present_value.rs`](https://github.com/TheAlgorithms/Rust/blob/abff887fdf7475e3581416305538e3b25d2693a1/src/financial/present_value.rs). The Rust source's `(present_value * 100.0).round() / 100.0` differs from the [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/present_value.py) and [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Financial/PresentValue.cs) at exact half-cent values: Rust rounds away from zero, while Python and C# use ties to even.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm present_value_rust --language rust
python3 benchmarks/run_i64_array_float64.py --algorithm present_value_rust
python3 benchmarks/verify_i64_array_float64.py --algorithm present_value_rust
```

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/p/present_value_rust.c`](../../../c/p/present_value_rust.c) |
| C3 | [`c3/p/present_value_rust.c3`](../../../c3/p/present_value_rust.c3) |
| C++ | [`cpp/p/present_value_rust.cpp`](../../../cpp/p/present_value_rust.cpp) |
| Elisa | [`elisa/p/present_value_rust.elisa`](../../../elisa/p/present_value_rust.elisa) |
| Nim | [`nim/p/present_value_rust.nim`](../../../nim/p/present_value_rust.nim) |
| Odin | [`odin/p/present_value_rust.odin`](../../../odin/p/present_value_rust.odin) |
| Rust | [`rust/p/present_value_rust.rs`](../../../rust/p/present_value_rust.rs) |
| V | [`v/p/present_value_rust.v`](../../../v/p/present_value_rust.v) |
| Zig | [`zig/p/present_value_rust.zig`](../../../zig/p/present_value_rust.zig) |
