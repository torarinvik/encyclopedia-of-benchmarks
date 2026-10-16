# Bezier curve point and tangent

Evaluate a two-dimensional Bezier curve and its derivative at one parameter. The implementation uses the Bernstein basis from the pinned Python source and the derivative identity based on adjacent control-point differences. Plotting is outside the benchmark contract.

## Contract

- Input is `[point_count, parameter_millionths, x0, y0, x1, y1, ...]`. There are 1–16 control points, the parameter is 0–1,000,000 inclusive, and integer control coordinates are bounded to ±1,000,000.
- Output is four signed 64-bit values `[x, y, dx, dy]`, each scaled by 1,000,000 and rounded to nearest with ties away from zero. The function returns 32 output bytes. Invalid inputs return `-1`; insufficient output capacity returns `-2`.
- Fixed-point input/output keeps the interface portable and makes all language results directly comparable. The parameter and coordinates are bounded so the double-precision evaluation has ample headroom before output quantization.

## Source normalization

The pinned Python module uses SciPy’s binomial coefficient helper, accepts floating-point points and parameters, and also includes matplotlib plotting. The shared contract replaces SciPy with a small exact integer binomial recurrence, restricts inputs to bounded integer coordinates and a millionth-grid parameter, and quantizes returned point and derivative values. Its basis-function method is an intermediate in the curve evaluation; plotting is excluded.

## Workload and verification

[`workload.json`](workload.json) covers a constant point, line endpoints and midpoint, quadratic and cubic curves, negative coordinates, maximum degree, malformed inputs, and output capacity. Verify with `python3 benchmarks/verify_bezier_curve.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1`.

## Pinned source

- TheAlgorithms/Python [`bezier_curve.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/graphics/bezier_curve.py)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/bezier_curve.c`](../../../c/b/bezier_curve.c) |
| C3 | [`c3/b/bezier_curve.c3`](../../../c3/b/bezier_curve.c3) |
| C++ | [`cpp/b/bezier_curve.cpp`](../../../cpp/b/bezier_curve.cpp) |
| Elisa | [`elisa/b/bezier_curve.elisa`](../../../elisa/b/bezier_curve.elisa) |
| Nim | [`nim/b/bezier_curve.nim`](../../../nim/b/bezier_curve.nim) |
| Odin | [`odin/b/bezier_curve.odin`](../../../odin/b/bezier_curve.odin) |
| Rust | [`rust/b/bezier_curve.rs`](../../../rust/b/bezier_curve.rs) |
| V | [`v/b/bezier_curve.v`](../../../v/b/bezier_curve.v) |
| Zig | [`zig/b/bezier_curve.zig`](../../../zig/b/bezier_curve.zig) |
