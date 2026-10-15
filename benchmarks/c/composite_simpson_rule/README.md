# Composite Simpson rule

Approximate a definite integral with composite Simpson quadrature. The pinned C++ source exposes `evaluate_by_simpson(N, h, a, func)`: it evaluates the callback at `x_i = a + i*h`, applies endpoint weights 1, odd-index weights 4, even-index weights 2, then multiplies the sum by `h/3`. The caller computes `h=(b-a)/N`; its default interval and step count are `[1,3]` and `N=16`.

## Contract

The `float64_pair` input is `[interval_count, function_selector]`. The interval count must be an exact even integer from 2 through 128. The selector must be an exact integer from 0 through 3 and chooses one of the four functions defined in the source: `sqrt(x)+log(x)`, `exp(-x)*(4-x^2)`, `sqrt(2*x^3+3)`, or `x+log(2*x+1)`. The integration interval is fixed to `[1,3]`, so all four functions stay finite and real for every supported sample point. The return value is the binary64 quadrature result; invalid inputs return `-1.0`.

The pinned function accepts a callback and caller-supplied interval parameters. This benchmark adapts its default interval and four bundled sample callbacks to the two-argument ABI. It follows the source's iterative `x += h` sampling and weighted-sum order. The source documents even `N` and asserts positive `N` and `a < b` in its command-line caller; the bounded contract requires a positive even count.

[`workload.json`](workload.json) includes each source callback at the default count, the smallest and largest supported counts, and invalid count/selector cases. The shared `float64_pair` runner validates expected results against the source's iterative sampling and weighted-sum order before recording. The pinned [C++ implementation](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/numerical_methods/composite_simpson_rule.cpp) is at commit `fdcc29b0ac2848e9d1a8d926e171cc5b39f97759`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/composite_simpson_rule.c`](../../../c/c/composite_simpson_rule.c) |
| C3 | [`c3/c/composite_simpson_rule.c3`](../../../c3/c/composite_simpson_rule.c3) |
| C++ | [`cpp/c/composite_simpson_rule.cpp`](../../../cpp/c/composite_simpson_rule.cpp) |
| Elisa | [`elisa/c/composite_simpson_rule.elisa`](../../../elisa/c/composite_simpson_rule.elisa) |
| Nim | [`nim/c/composite_simpson_rule.nim`](../../../nim/c/composite_simpson_rule.nim) |
| Odin | [`odin/c/composite_simpson_rule.odin`](../../../odin/c/composite_simpson_rule.odin) |
| Rust | [`rust/c/composite_simpson_rule.rs`](../../../rust/c/composite_simpson_rule.rs) |
| V | [`v/c/composite_simpson_rule.v`](../../../v/c/composite_simpson_rule.v) |
| Zig | [`zig/c/composite_simpson_rule.zig`](../../../zig/c/composite_simpson_rule.zig) |
