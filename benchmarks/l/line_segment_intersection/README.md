# Line Segment Intersection

This benchmark reports whether two finite closed line segments intersect. It uses exact integer orientation tests and returns a boolean as `1` or `0`.

## Contract

- Input is eight signed 64-bit integers: `(x1,y1,x2,y2,x3,y3,x4,y4)`.
- Each coordinate is in `[-10,000, 10,000]`.
- Return `1` when the closed segments intersect, including endpoint touches and any collinear overlap. Return `0` when they are disjoint. The result has no output bytes.
- A zero-length segment is treated as a point. It intersects another segment when that point lies on the other segment; two equal point segments intersect.
- Invalid input returns `-1`.
- Time and auxiliary storage are both `O(1)`.

The two pinned C++ files are duplicates. Their orientation branches contain sign tests that can report false positives, and one collinear branch checks the wrong endpoint orientation. The Python source expresses the intended CLRS orientation algorithm, including endpoint containment. This benchmark follows that boolean predicate and fixes the C++ source issues while using an integer coordinate range that keeps all cross products exact in signed 64-bit arithmetic.

This is distinct from [`line_intersection`](../line_intersection/README.md), which handles infinite lines as well as finite segments and returns a unique intersection point. Here the input always describes finite segments and the output is only whether they intersect.

[`workload.json`](workload.json) covers proper crossings, endpoint and T-junction touches, collinear overlap and separation, parallel segments, point segments, and invalid input.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm line_segment_intersection --language rust
```

## Upstream references

- [TheAlgorithms/C++ `line_segment_intersection.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/geometry/line_segment_intersection.cpp)
- [TheAlgorithms/C++-1 `line_segment_intersection.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/geometry/line_segment_intersection.cpp)
- [TheAlgorithms/Python `segment_intersection.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/geometry/segment_intersection.py)
