# Olden Barnes–Hut gravity query

This package exposes the 3D hierarchical gravity-field query from the pinned
Olden `bh` benchmark. It builds an octree of point masses, computes each cell's
center of mass, and walks the tree for one query point. This is distinct from
the repository's direct pairwise [`n_body_simulation`](../n_body_simulation/README.md)
and `benchmarkgame_nbody` benchmarks.

## Contract

The `float64_slice_io` symbol is `olden_bh`. Input is
`[body_count, opening_tolerance, softening, query_x, query_y, query_z,
(x,y,z,mass)...]`. There are 2–16 bodies, integer coordinates in `[-32,32]`,
unique body positions, masses in `[1,16]`, opening tolerance in `[0,2]`, and
softening in `[0,1]`. The query point is bounded to the same coordinate range
and lies outside the bodies' axis-aligned bounding box, avoiding self-force
and singular query cases.

The tree uses eight children per internal cell. Each cell aggregates total
mass and mass-weighted center of mass. A cell opens when
`opening_tolerance² * distance² < cell_side²`; otherwise its center of mass is
used as one monopole interaction. Traversal visits children in index order
0–7. The source's default build does not enable its `QUADPOLE` branch. The
output is `[potential, ax, ay, az]`, with the pinned negative-potential and
acceleration accumulation order. Invalid inputs return `-1`; null output or
capacity below four returns `-2` without writing. Comparisons use absolute and
relative tolerance `1e-12`.

The bounded field-query kernel omits upstream random Plummer-body generation,
the leapfrog time integration, processor partitioning, and the source's
launcher-scale 2,000/40,000-body workloads. The source launcher selects `-lm`
and `-DTORONTO` and defaults to 40,000 bodies and 30 steps (2,000 bodies and 5
steps with `SMALL_PROBLEM_SIZE`).

## Pinned source and license

- [`newbh.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bh/newbh.c)
- [`walksub.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bh/walksub.c)
- [`info.sh`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/bh/info.sh)

The pinned C headers identify Joshua E. Barnes (1991) and refer to
`olden_v1.0/COPYRIGHT`; that file is not present at the referenced path in this
snapshot. The local implementations are independently written and do not
assume an inferred license grant.

## Workload and ports

See [`workload.json`](workload.json) and the independent
[`olden_bh_oracle`](../../olden_bh_oracle.py).

| Language | Source |
| --- | --- |
| C | [c/o/olden_bh.c](../../../c/o/olden_bh.c) |
| C3 | [c3/o/olden_bh.c3](../../../c3/o/olden_bh.c3) |
| C++ | [cpp/o/olden_bh.cpp](../../../cpp/o/olden_bh.cpp) |
| Elisa | [elisa/o/olden_bh.elisa](../../../elisa/o/olden_bh.elisa) |
| Nim | [nim/o/olden_bh.nim](../../../nim/o/olden_bh.nim) |
| Odin | [odin/o/olden_bh.odin](../../../odin/o/olden_bh.odin) |
| Rust | [rust/o/olden_bh.rs](../../../rust/o/olden_bh.rs) |
| V | [v/o/olden_bh.v](../../../v/o/olden_bh.v) |
| Zig | [zig/o/olden_bh.zig](../../../zig/o/olden_bh.zig) |
