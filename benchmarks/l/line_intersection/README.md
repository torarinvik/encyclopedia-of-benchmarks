# Line Intersection

This benchmark computes the unique intersection point of two infinite lines or two closed line segments. It uses determinant arithmetic over bounded integer coordinates and returns the point as two binary64 values.

## Contract

- Input is nine signed 64-bit integers: `(x1,y1,x2,y2,x3,y3,x4,y4,mode)`.
- Each coordinate is in `[-10,000, 10,000]`. `mode=0` treats the endpoint pairs as infinite lines; `mode=1` treats them as closed segments.
- Return `1` and write `(x,y)` as two little-endian IEEE-754 binary64 values when there is one unique intersection point. Segment mode includes endpoint touches.
- Return `0` with no output for parallel or coincident lines, including collinear segment overlaps, because those cases do not have one unique intersection.
- In segment mode, a zero-length segment is a point: it intersects when that point lies on the other segment. Two equal point segments return that point. In infinite-line mode, a zero-length input is invalid because it does not define a line.
- Invalid input returns `-1`. When a unique point must be written, null or insufficient output storage returns `-2` without writing; no output storage is needed when there is no unique point.
- Time and auxiliary storage are both `O(1)`.

The coordinate bound keeps determinants and intersection numerators exact in signed 64-bit arithmetic. Converting the exact numerator and denominator to binary64 gives a deterministic shared result for all ports.

[`workload.json`](workload.json) includes crossings, endpoint touches, parallel and coincident lines, line-versus-segment mode differences, point segments, invalid values, and rational coordinates.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm line_intersection --language rust
```

## Upstream references

- [TheAlgorithms/Java `LineIntersection.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/geometry/LineIntersection.java)
- [TheAlgorithms/Python `line_intersection.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/line_intersection.py)
- [TheAlgorithms/C++ `line_segment_intersection.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/geometry/line_segment_intersection.cpp)
- [TheAlgorithms/Python `segment_intersection.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/segment_intersection.py)

The Java/Python line APIs return a point when available, and Python can extend the computation to infinite lines. The existing C++/Python segment APIs only answer whether two finite segments intersect, so they remain a separate benchmark family.
