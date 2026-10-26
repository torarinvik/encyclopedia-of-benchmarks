# Two-Dimensional Orthogonal Range Reporting

This package implements bounded static 2D orthogonal range reporting on an integer grid, a concrete slice of the discrete-grid structures surveyed in the Encyclopedia of Algorithms, DOI suffix 631. It reports point IDs for closed rectangles; it does not count or aggregate points.

## Contract

- ABI: i64_array_bytes_output; symbol: orthogonal_range_reporting_2d.
- Input is [n,q, x0,y0,..., x(n-1),y(n-1), then q rectangles as x_low,x_high,y_low,y_high]. There are 1–8 distinct points, 1–8 queries, and coordinates/bounds are in 0..15.
- Build a balanced segment tree over points sorted by (x,y,id). Each node keeps its point IDs sorted by (y,id). For each rectangle, binary-search x bounds, decompose the resulting rank interval into canonical tree nodes, binary-search each y catalog, and report all hits.
- Output is [q, hit_count, point_ids...] with IDs in ascending input order for each query, encoded as little-endian signed i64 words. Invalid input returns -1; null or short output returns -2 without writes. Maximum input is 50 integers and maximum output is 584 bytes.

The chapter surveys many discrete-grid range-reporting and range-searching structures; this package pins the 2D static reporting operation and a bounded range-tree profile. See [RIGHTS.md](RIGHTS.md) for attribution.

## Workload and independent check

[workload.json](workload.json) covers mixed and empty rectangles, closed boundaries, maximum point/query counts, malformed bounds/coordinates, and capacity errors. The primary [oracle](../../orthogonal_range_reporting_2d_oracle.py) answers from a segment tree with y-sorted node catalogs. The independent [verifier](../../orthogonal_range_reporting_2d_verifier_oracle.py) scans the original points per rectangle.

## Implementations

| Language | Port |
|---|---|
| C | [c/o/orthogonal_range_reporting_2d.c](../../../c/o/orthogonal_range_reporting_2d.c) |
| C3 | [c3/o/orthogonal_range_reporting_2d.c3](../../../c3/o/orthogonal_range_reporting_2d.c3) |
| C++ | [cpp/o/orthogonal_range_reporting_2d.cpp](../../../cpp/o/orthogonal_range_reporting_2d.cpp) |
| Elisa | [elisa/o/orthogonal_range_reporting_2d.elisa](../../../elisa/o/orthogonal_range_reporting_2d.elisa) |
| Nim | [nim/o/orthogonal_range_reporting_2d.nim](../../../nim/o/orthogonal_range_reporting_2d.nim) |
| Odin | [odin/o/orthogonal_range_reporting_2d.odin](../../../odin/o/orthogonal_range_reporting_2d.odin) |
| Rust | [rust/o/orthogonal_range_reporting_2d.rs](../../../rust/o/orthogonal_range_reporting_2d.rs) |
| V | [v/o/orthogonal_range_reporting_2d.v](../../../v/o/orthogonal_range_reporting_2d.v) |
| Zig | [zig/o/orthogonal_range_reporting_2d.zig](../../../zig/o/orthogonal_range_reporting_2d.zig) |

