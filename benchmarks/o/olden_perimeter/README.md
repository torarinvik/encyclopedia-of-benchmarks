# Olden quadtree perimeter

This benchmark ports the TORONTO configuration of Olden's `perimeter` program. It recursively subdivides a quadtree and sums exposed black-cell edges. This is distinct from the existing `perimeter` benchmark, which multiplies the side count and side length of a regular polygon.

## Bounded contract

Input is a one-element signed 64-bit array containing a refinement level. The local suite accepts levels 9 through 11, covering the pinned `info.sh` launcher choices (9 for `SMALL_PROBLEM_SIZE`, 11 otherwise) and the Makefile's default level 10. Other lengths or levels return -1.

The pinned `-DTORONTO` main calls `MakeTree(2048*1024, ...)` and `perimeter(tree, 4096)`. With levels 9 through 11, the `MakeTree` refinement depth is exhausted before its `size < 512` early-white cutoff can apply. The generated tree is therefore a full, uniformly black quadtree. Its outer boundary is 4 × 4096 = 16,384 units at every accepted level. The language ports traverse this implicit subdivision and sum the same exposed boundary edges without allocating millions of nodes. The upstream program also prints its leaf count; the scalar ABI reports the perimeter only.

## Provenance and license

The source is [`lac-dcc/Benchmarks` at commit `5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/tree/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/perimeter). The relevant source files are [`args.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/perimeter/args.c), [`main.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/perimeter/main.c), [`maketree.c`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/perimeter/maketree.c), and [`perimeter.h`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/Olden/perimeter/perimeter.h). The source comments refer to `olden_v1.0/COPYRIGHT`, but that file is absent from the pinned repository tree, so the upstream license cannot be established from this snapshot. These local ports are independently written and cite the source for algorithm provenance.

## Workload and ports

[`workload.json`](workload.json) covers the three bounded levels, malformed lengths, and out-of-range levels. The independent [oracle](../olden_perimeter_oracle.py) computes the exposed boundary length from the bounded uniform-grid semantics.

| Language | Implementation |
| --- | --- |
| C | [`c/o/olden_perimeter.c`](../../../c/o/olden_perimeter.c) |
| C3 | [`c3/o/olden_perimeter.c3`](../../../c3/o/olden_perimeter.c3) |
| C++ | [`cpp/o/olden_perimeter.cpp`](../../../cpp/o/olden_perimeter.cpp) |
| Elisa | [`elisa/o/olden_perimeter.elisa`](../../../elisa/o/olden_perimeter.elisa) |
| Nim | [`nim/o/olden_perimeter.nim`](../../../nim/o/olden_perimeter.nim) |
| Odin | [`odin/o/olden_perimeter.odin`](../../../odin/o/olden_perimeter.odin) |
| Rust | [`rust/o/olden_perimeter.rs`](../../../rust/o/olden_perimeter.rs) |
| V | [`v/o/olden_perimeter.v`](../../../v/o/olden_perimeter.v) |
| Zig | [`zig/o/olden_perimeter.zig`](../../../zig/o/olden_perimeter.zig) |
