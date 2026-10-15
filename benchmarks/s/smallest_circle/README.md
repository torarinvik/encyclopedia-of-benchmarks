# Smallest Enclosing Circle

This benchmark finds the smallest circle that contains a bounded set of integer points.

## Contract

- Input is a flattened sequence `(x0,y0,...,xN-1,yN-1)` with 1 to 12 points. Each signed 64-bit coordinate is in `[-100, 100]`.
- Return `1` and write the circle center `(center_x, center_y)` and radius as three little-endian IEEE-754 binary64 values. A single input point returns radius zero.
- Candidate circles are enumerated deterministically: first circumcircles from noncollinear triples in increasing index order, then diameter circles from pairs in increasing index order. A candidate is accepted if every point is within its radius, allowing `1e-12` squared-distance slack for floating-point rounding. Equal-radius candidates replace the current result, so the last valid candidate in this order wins.
- Invalid input returns `-1`. Null or fewer than 24 output bytes returns `-2` without writing.
- Time complexity is `O(N^4)` and auxiliary storage is `O(N)`.

Both pinned C++ sources enumerate three-point circumcircles and two-point diameter circles, checking each candidate against every input point. They are byte-for-byte algorithmic duplicates and contain a documented failing test; this benchmark keeps that deterministic exhaustive strategy while skipping collinear triples, handling a singleton explicitly, and computing circumcenters with the standard determinant formula. The resulting contract is bounded to keep the exhaustive search practical. Convex hull and point-distance benchmarks solve different problems: a hull returns boundary vertices, while this algorithm returns an enclosing circle.

[`workload.json`](workload.json) includes singleton and duplicate sets, pair-defined circles, acute and obtuse support triples, a square with tied diameter candidates, collinear points, and invalid inputs.

Build with the `i64_array_bytes_output` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm smallest_circle --language rust
```

## Upstream references

- [TheAlgorithms/C++ `smallest_circle.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/smallest_circle.cpp)
- [TheAlgorithms/C++-1 `smallest_circle.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/smallest_circle.cpp)
