# Braikenridge–Maclaurin conic construction

This benchmark ports the determinant construction from the pinned TheAlgorithms/Python [`BraikMac`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/braik_mac_construction.py), which computes the six coefficients of the conic through five points.

## Input and output

Input is ten signed 64-bit integers giving five `(x, y)` points in order. Coordinates are bounded to -10..10. This integer domain makes the six 5×5 determinants exact in every target language; their magnitudes remain within signed 64-bit range.

The result is the six signed determinant coefficients `[a, b, c, d, e, f]`, serialized as little-endian signed 64-bit values. The pinned Python source formats these values to two significant digits in an equation string. This contract returns the underlying coefficients before display formatting, which avoids platform-specific float determinant and string-formatting differences. The column layouts and signs match the source's six matrices. Degenerate point sets are valid and can yield all-zero coefficients. Invalid input or insufficient output capacity returns `-2`.

## Workloads

The workload includes the upstream example, points on a circle and parabola, collinear and duplicate points, negative coordinates, coordinate limits, and insufficient output capacity.
