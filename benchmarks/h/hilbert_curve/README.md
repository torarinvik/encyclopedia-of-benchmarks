# Hilbert curve

This benchmark ports the pinned Python recursive Hilbert curve point generator and omits its plotting wrapper. The input is `[level, angle_quadrants]`, with level 1–6 and initial angle 0–3 quarter-turns. The center is fixed at `(0, 0)` and side length at `1`, as in the source example.

The result is the curve's ordered point list, flattened as alternating x/y signed integers. Coordinates are scaled by `2^(level+1)`, which represents every generated dyadic point exactly. Rotation preserves the source's cyclic point-list rotation; the first and fourth recursive quadrants reverse their point order. Invalid input returns -1, and insufficient output capacity returns -2. See the [pinned Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/hilbert_curve.py).
