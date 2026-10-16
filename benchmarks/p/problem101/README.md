# Project Euler Problem 101: Optimum polynomial fits

## Contract

`problem101(order)` sums the first incorrect terms (FITs) for the pinned alternating degree-10 polynomial, using interpolation orders 1 through `order`. The workload supports orders 0..10; a negative order preserves the source's empty-range result 0. Orders above 10 return `-1`, since the source's search would not terminate after the full degree-10 polynomial is interpolated. The canonical order-10 result is 37,076,114,526.

The ports build the first `order` sequence values and use forward finite differences for each prefix length `k`. They evaluate that exact interpolating polynomial at successive integer inputs until it first differs from the generating polynomial, then add that predicted term. This preserves the source's prefix traversal and first-mismatch stopping behavior without floating-point matrix elimination.

## Source review

The pinned Python [`sol1`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/project_euler/problem_101/sol1.py) uses `u(n)=1-n+n²-...+n¹⁰`, builds values for `n=1..order`, and interpolates prefixes of lengths 1 through `order`. For each polynomial it starts at `x=1`, advances while the interpolant equals `u(x)`, and adds the first unequal interpolant value. Its default order is 10. The package preserves that traversal and stopping rule; exact finite differences evaluate the same integer-valued prefix interpolants.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/p/problem101.c](../../../c/p/problem101.c) |
| C3 | [c3/p/problem101.c3](../../../c3/p/problem101.c3) |
| C++ | [cpp/p/problem101.cpp](../../../cpp/p/problem101.cpp) |
| Elisa | [elisa/p/problem101.elisa](../../../elisa/p/problem101.elisa) |
| Nim | [nim/p/problem101.nim](../../../nim/p/problem101.nim) |
| Odin | [odin/p/problem101.odin](../../../odin/p/problem101.odin) |
| Rust | [rust/p/problem101.rs](../../../rust/p/problem101.rs) |
| V | [v/p/problem101.v](../../../v/p/problem101.v) |
| Zig | [zig/p/problem101.zig](../../../zig/p/problem101.zig) |
