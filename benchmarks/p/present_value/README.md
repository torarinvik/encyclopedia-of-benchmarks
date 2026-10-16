# Present value

Compute the present value of yearly cash flows using the pinned Python and C# formulas, then round the binary64 result to two decimal places with ties to even.

## Contract

- Input is `[count, discount_rate_ppm, cash_flow_0_milli, ...]` in a signed 64-bit array. Decode the rate by dividing by 1,000,000 and each cash flow by 1,000.
- Require 1 through 8 cash flows, a rate of 0 or 1,000,000 ppm (0 or 1), and each cash flow to be a multiple of 125 milli in [-1,000,000, 1,000,000]. Packed length must equal `count + 2`; parse up to 11 values to detect overlong malformed input.
- For each cash flow at index `i`, compute `cash_flow / (1 + rate)^i`, add terms in input order, then apply Python binary64 `round(value, 2)` ties-to-even semantics. Index zero is undiscounted.
- Empty, malformed, out-of-range, or null-pointer input returns `-1e300`. Valid results are finite and compared with absolute and relative tolerance `1e-12`.

The restricted rates and cash flows keep each term and the total exactly representable in binary64. This makes the Python and C# rounding results agree across .NET runtime versions, including half-cent values. The workload covers positive and negative ties, an adapted source-shaped example, boundaries, and invalid packed layouts. Its independent formula oracle is [`present_value_oracle.py`](../../present_value_oracle.py).

The benchmark adapts [TheAlgorithms/Python `present_value.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/financial/present_value.py) and [TheAlgorithms/C-Sharp `PresentValue.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Financial/PresentValue.cs). The C# source uses `Math.Round(value, 2)`; the restricted binary-exact workload avoids the runtime-version-dependent results that can occur for other binary64 values.

## Implementations

| Language | Port |
| --- | --- |
| C | [`c/p/present_value.c`](../../../c/p/present_value.c) |
| C3 | [`c3/p/present_value.c3`](../../../c3/p/present_value.c3) |
| C++ | [`cpp/p/present_value.cpp`](../../../cpp/p/present_value.cpp) |
| Elisa | [`elisa/p/present_value.elisa`](../../../elisa/p/present_value.elisa) |
| Nim | [`nim/p/present_value.nim`](../../../nim/p/present_value.nim) |
| Odin | [`odin/p/present_value.odin`](../../../odin/p/present_value.odin) |
| Rust | [`rust/p/present_value.rs`](../../../rust/p/present_value.rs) |
| V | [`v/p/present_value.v`](../../../v/p/present_value.v) |
| Zig | [`zig/p/present_value.zig`](../../../zig/p/present_value.zig) |
