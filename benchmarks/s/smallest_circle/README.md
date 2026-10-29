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

## Language ports

The current repository contains the same bounded exhaustive candidate enumeration in all nine supported languages.

| Language | Source |
| --- | --- |
| C | [c/s/smallest_circle.c](../../../c/s/smallest_circle.c) |
| C3 | [c3/s/smallest_circle.c3](../../../c3/s/smallest_circle.c3) |
| C++ | [cpp/s/smallest_circle.cpp](../../../cpp/s/smallest_circle.cpp) |
| Elisa | [elisa/s/smallest_circle.elisa](../../../elisa/s/smallest_circle.elisa) |
| Nim | [nim/s/smallest_circle.nim](../../../nim/s/smallest_circle.nim) |
| Odin | [odin/s/smallest_circle.odin](../../../odin/s/smallest_circle.odin) |
| Rust | [rust/s/smallest_circle.rs](../../../rust/s/smallest_circle.rs) |
| V | [v/s/smallest_circle.v](../../../v/s/smallest_circle.v) |
| Zig | [zig/s/smallest_circle.zig](../../../zig/s/smallest_circle.zig) |

## Upstream references

- [TheAlgorithms/C++ `smallest_circle.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/others/smallest_circle.cpp)
- [TheAlgorithms/C++-1 `smallest_circle.cpp`](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/others/smallest_circle.cpp)
