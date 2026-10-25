# Olden Voronoi divide-and-conquer kernel

This bounded package follows the quad-edge divide-and-conquer Delaunay core
and its Voronoi dual from the pinned Olden [`voronoi`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/voronoi) benchmark.
Its method differs from the local `fortune_voronoi` package, which uses a
Fortune beachline sweep.

## Contract

- ABI: `i64_array_scalar`, symbol `olden_voronoi`.
- Input is `[point_count, x0, y0, ...]`, where point count is 3 or 5 and
  coordinates are integers in `[-8,8]`, supplied in strictly increasing x
  order.
- The deterministic point tree follows the source base cases. Three sites use
  the 3-point triangulation case. Five sites use two-point and three-point
  subproblems, then the source quad-edge `do_merge` routine.
- Collinear triples and cocircular quadruples are rejected. Valid diagrams
  have a unique Delaunay triangulation.
- The result is a scalar checksum of the finite Voronoi vertices and dual
  topology: for each Delaunay triangle, add
  `round_half_up(1000*cx) + 2*round_half_up(1000*cy)` for its circumcenter;
  then add 100 per triangle, 10 per finite Voronoi segment, one per boundary
  ray, and one per Delaunay edge. Rounding is `floor(x+0.5)`.
- The independent [oracle](../../olden_voronoi_oracle.py) enumerates empty
  circumcircles, rather than using quad-edge topology.

## Provenance and license

The pinned launcher compiles `args.c`, `newvor.c`, `output.c`, and `vector.c`
with `-lm -DTORONTO`. Source headers refer to `olden_v1.0/COPYRIGHT`, which is
absent from the pinned repository snapshot; no upstream license is inferred.
The ports are independently written from the source's quad-edge data model,
geometric predicates, divide-and-conquer merge, and dual construction.

## Language ports

| Language | Source |
| --- | --- |
| C | [c/v/olden_voronoi.c](../../../c/v/olden_voronoi.c) |
| C3 | [c3/v/olden_voronoi.c3](../../../c3/v/olden_voronoi.c3) |
| C++ | [cpp/v/olden_voronoi.cpp](../../../cpp/v/olden_voronoi.cpp) |
| Elisa | [elisa/v/olden_voronoi.elisa](../../../elisa/v/olden_voronoi.elisa) |
| Nim | [nim/v/olden_voronoi.nim](../../../nim/v/olden_voronoi.nim) |
| Odin | [odin/v/olden_voronoi.odin](../../../odin/v/olden_voronoi.odin) |
| Rust | [rust/v/olden_voronoi.rs](../../../rust/v/olden_voronoi.rs) |
| V | [v/v/olden_voronoi.v](../../../v/v/olden_voronoi.v) |
| Zig | [zig/v/olden_voronoi.zig](../../../zig/v/olden_voronoi.zig) |

## Pinned source files

- [`newvor.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/voronoi/newvor.c)
- [`output.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/voronoi/output.c)
- [`vector.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/voronoi/vector.c)
- [`defines.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/voronoi/defines.h)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/voronoi/info.sh)
