# Lens Formulae

This package follows the three functions in pinned [TheAlgorithms/Python `lens_formulae.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/lens_formulae.py). Each solves the thin-lens reciprocal equation for one variable:

- Operation `0`, focal length: inputs `[object_distance, image_distance]`; computes `1 / ((1 / image_distance) - (1 / object_distance))`.
- Operation `1`, object distance: inputs `[focal_length, image_distance]`; computes `1 / ((1 / image_distance) - (1 / focal_length))`.
- Operation `2`, image distance: inputs `[focal_length, object_distance]`; computes `1 / ((1 / object_distance) + (1 / focal_length))`.

The `i64_array_float64` ABI accepts exactly `[operation, first, second]`. The two distance operands are nonzero signed integers in `[-1,000,000, 1,000,000]`. Their numeric units are preserved, so each result uses the same distance unit. Operations `0` and `1` reject equal operands because their reciprocal difference is zero; operation `2` rejects opposite operands of equal magnitude because its reciprocal sum is zero. Invalid layouts, selectors, bounds, or singular cases return `-1e300`.

The ports preserve each source reciprocal expression and operand order. The input bound keeps all reciprocals and results finite; singular combinations are excluded explicitly. The nearby [`thin_lens`](../../t/thin_lens/README.md) benchmark is related but distinct: it covers magnification and image classification, while this package also exposes focal-length and object-distance solves.

The `i64_array_float64` runner validates the selected source-ordered reciprocal expression, the nonzero operand bounds, and each operation's singular denominator.

Runtime and auxiliary space are O(1). The workload covers every operation, signed distances, and invalid and singular cases.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/l/lens_formulae.c`](../../../c/l/lens_formulae.c) |
| C3 | [`c3/l/lens_formulae.c3`](../../../c3/l/lens_formulae.c3) |
| C++ | [`cpp/l/lens_formulae.cpp`](../../../cpp/l/lens_formulae.cpp) |
| Elisa | [`elisa/l/lens_formulae.elisa`](../../../elisa/l/lens_formulae.elisa) |
| Nim | [`nim/l/lens_formulae.nim`](../../../nim/l/lens_formulae.nim) |
| Odin | [`odin/l/lens_formulae.odin`](../../../odin/l/lens_formulae.odin) |
| Rust | [`rust/l/lens_formulae.rs`](../../../rust/l/lens_formulae.rs) |
| V | [`v/l/lens_formulae.v`](../../../v/l/lens_formulae.v) |
| Zig | [`zig/l/lens_formulae.zig`](../../../zig/l/lens_formulae.zig) |
