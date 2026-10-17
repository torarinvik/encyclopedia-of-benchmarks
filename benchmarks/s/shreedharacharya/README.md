# Shreedharacharya quadratic roots

This package ports the pinned Dart `shreedharacharya` function. It solves `a*x² + b*x + c = 0` with the direct discriminant formula, returning zero, one, or two real roots.

## Contract

- ABI: `float64_slice_io`; input is exactly `[a,b,c]` as finite float64 values.
- Require `|a|` in `[1e-6, 1,000,000]` and `|b|, |c|` at most `1,000,000`. The nonzero lower bound on `|a|` keeps all intermediate and root values finite.
- Compute `d = b*b - 4*a*c`. For `d < 0`, return zero roots and an empty output. For `d == 0`, return the single root `-b/(2*a)`. For `d > 0`, return `(-b + sqrt(d))/(2*a)` followed by `(-b - sqrt(d))/(2*a)`, preserving the Dart source's order.
- The return value is the number of roots (0, 1, or 2). Invalid input returns `-1`. A null output pointer or a capacity smaller than the returned root count returns `-2` without writing. The float64-slice ABI requires a nonnull output pointer even for a zero-root result. Workspace is two float64 elements.
- Use absolute and relative tolerances of `1e-12` for the floating-point roots. The direct formula is kept to match the source, including its cancellation behavior.

The pinned Dart function prints `Imaginary roots` when `d < 0` and still returns an empty list; the console side effect is omitted by this numeric ABI adapter. Its return arity is distinct from the MATLAB `shree_dharacharya_formula` benchmark: a negative discriminant produces zero roots here.

## Workload and oracle

[`workload.json`](workload.json) has 24 cases covering the pinned repeated-root example, all three root counts, source ordering, irrational and fractional roots, a negative leading coefficient, coefficient boundaries, malformed inputs, and invalid coefficient ranges. The verifier also probes a null output pointer and insufficient capacity. The independent [oracle](../../shreedharacharya_oracle.py) uses the same direct formula and preserves the returned list length.

Pinned source: [TheAlgorithms/Dart `shreedharacharya.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/maths/shreedharacharya.dart), function `shreedharacharya`.

## Implementations

| Language | Port |
|---|---|
| C | [`c/s/shreedharacharya.c`](../../../c/s/shreedharacharya.c) |
| C3 | [`c3/s/shreedharacharya.c3`](../../../c3/s/shreedharacharya.c3) |
| C++ | [`cpp/s/shreedharacharya.cpp`](../../../cpp/s/shreedharacharya.cpp) |
| Elisa | [`elisa/s/shreedharacharya.elisa`](../../../elisa/s/shreedharacharya.elisa) |
| Nim | [`nim/s/shreedharacharya.nim`](../../../nim/s/shreedharacharya.nim) |
| Odin | [`odin/s/shreedharacharya.odin`](../../../odin/s/shreedharacharya.odin) |
| Rust | [`rust/s/shreedharacharya.rs`](../../../rust/s/shreedharacharya.rs) |
| V | [`v/s/shreedharacharya.v`](../../../v/s/shreedharacharya.v) |
| Zig | [`zig/s/shreedharacharya.zig`](../../../zig/s/shreedharacharya.zig) |
