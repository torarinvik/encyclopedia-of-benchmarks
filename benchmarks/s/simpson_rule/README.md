# Simpson rule

This package adapts the pinned Python `method_2` implementation with its module-level integrand `f(x) = (x - 0) * (x - 0)`. It approximates the integral on `[0,b]` using ten Simpson intervals.

## Contract

- ABI: `float64_pair`, with input `[b, steps]`.
- The adapter fixes the lower bound to `a=0` and accepts only `b` equal to `1.0`, `2.0`, or `3.0`, with `steps` exactly `10.0`. These endpoints preserve the pinned strict repeated-addition sampling on every supported case.
- The result follows the Python source's operation order: `h=(b-a)/steps`, start `x=a+h`, visit samples while `x < b-h`, increment `x` by repeated addition, apply alternating interior weights 4 and 2, then add the endpoint and scale each term by `h/3`.
- Inputs outside the bounded slice return `-1e300`. Valid results are compared with input-scaled tolerance `1e-12`.

The source accepts arbitrary boundary lists and positive step counts; the bounded ABI narrows those parameters to keep the source's floating-point loop portable. The function's own default example uses `a=0`, `b=1`, and ten steps.

## Workload and source

[`workload.json`](workload.json) covers all three supported upper bounds, the source default, nonpositive and fractional step counts, and out-of-slice bounds. The independent [oracle](../../simpson_rule_oracle.py) reproduces the pinned repeated-addition loop and accumulation order.

Pinned source: [TheAlgorithms/Python `simpson_rule.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/simpson_rule.py), functions `method_2`, `make_points`, and `f`.

| Language | Port |
|---|---|
| C | [`c/s/simpson_rule.c`](../../../c/s/simpson_rule.c) |
| C3 | [`c3/s/simpson_rule.c3`](../../../c3/s/simpson_rule.c3) |
| C++ | [`cpp/s/simpson_rule.cpp`](../../../cpp/s/simpson_rule.cpp) |
| Elisa | [`elisa/s/simpson_rule.elisa`](../../../elisa/s/simpson_rule.elisa) |
| Nim | [`nim/s/simpson_rule.nim`](../../../nim/s/simpson_rule.nim) |
| Odin | [`odin/s/simpson_rule.odin`](../../../odin/s/simpson_rule.odin) |
| Rust | [`rust/s/simpson_rule.rs`](../../../rust/s/simpson_rule.rs) |
| V | [`v/s/simpson_rule.v`](../../../v/s/simpson_rule.v) |
| Zig | [`zig/s/simpson_rule.zig`](../../../zig/s/simpson_rule.zig) |
