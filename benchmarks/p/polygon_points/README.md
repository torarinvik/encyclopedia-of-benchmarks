# Polygon lattice points

This benchmark ports the pinned Rust polygon_points routine. It returns the number of interior lattice points using the source's triangulated integer area and boundary calculation.

## Contract

The i64_array_scalar input is [n, x0, y0, ..., x(n-1), y(n-1)]. It contains exactly 1 + 2*n values, with 3 <= n <= 32 and each coordinate in [-1000, 1000]. The parser admits 66 values so one trailing value beyond the maximum valid length can be rejected. Invalid framing or numeric bounds return -1.

Inputs are assumed to describe a simple integer polygon with nonzero area and no zero-length cyclic edge, including the closing edge. This geometric condition is a precondition, not a runtime validation: the source does not check simplicity or reject zero-length edges.

The source area routine sums anchored triangle cross products, divides the signed sum by two with integer truncation, then takes its absolute value. The boundary routine starts with n and adds abs(gcd(dx,dy))-1 for every cyclic edge. The final result is area + 1 - boundary/2, with integer division. Odd doubled-area and boundary values are allowed; their truncating halves cancel for simple lattice polygons. The coordinate and vertex bounds keep all intermediate arithmetic within signed 64-bit range.

## Pinned source and workload

The source is [TheAlgorithms/Rust polygon_points.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/geometry/polygon_points.rs) at commit fed66cb0c74c4a939ec5163648458a8c2b46fd4c. The workload includes the pinned triangle example, an odd-doubled-area triangle, a polygon with collinear consecutive edges, maximum coordinate and vertex bounds, and malformed framing. The independent oracle is in benchmarks/polygon_points_oracle.py.

## Implementations

| Language | Source |
| --- | --- |
| C | c/p/polygon_points.c |
| C3 | c3/p/polygon_points.c3 |
| C++ | cpp/p/polygon_points.cpp |
| Elisa | elisa/p/polygon_points.elisa |
| Nim | nim/p/polygon_points.nim |
| Odin | odin/p/polygon_points.odin |
| Rust | rust/p/polygon_points.rs |
| V | v/p/polygon_points.v |
| Zig | zig/p/polygon_points.zig |
