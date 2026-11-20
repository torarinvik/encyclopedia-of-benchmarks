# Three-dimensional Bird–Baker matching

This package benchmarks the explicit higher-dimensional extension of the
Bird–Baker row-reduction algorithm in the *Encyclopedia of Algorithms* chapter
“Multidimensional String Matching.” The 2D matcher is applied to distinct
pattern slices in each text slice; its occurrence marks become slice labels.
A KMP pass over those labels then finds the pattern-slice sequence along the
depth axis. The existing [2D Bird–Baker package](../two_dimensional_string_matching/README.md)
is the lower-dimensional base profile. This package does not implement the
separately cited Amir–Benson–Farach 3D method.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `three_dimensional_bird_baker_matching`.
- Input is `[R,C,D,PR,PC,PD,text...,pattern...]`. The text has dimensions
  `1..5` on each axis. Pattern dimensions are `1..4` and may not exceed the
  corresponding text dimensions. Values are symbols in `[0,3]`.
- Text and pattern values are stored as depth-major planes, with each plane
  row-major: index `((depth*rows)+row)*columns+column`.
- Output is `[count,(row,column,depth)*count]`, with zero-based positions in
  lexicographic `(row,column,depth)` order. Every exact overlapping occurrence
  is included.
- Maximum valid/parseable input lengths are 195/196 i64 words. There are at
  most 125 matches, so output is at most 3,008 bytes. Workspace is 8,192 bytes.
  Invalid input returns `-1`; null or insufficient output returns `-2` without
  writes.
- The primary reference runs 2D row-marking/KMP for each distinct pattern
  slice, labels those positions, then performs KMP along depth. The independent
  reference compares every 3D window cell by cell. Fixtures pin depth-major
  framing, coordinate order, overlapping matches, no-match output, malformed
  inputs, and output capacity handling.

## Source and rights

The source is Chapter 247, [“Multidimensional String Matching”](https://doi.org/10.1007/978-1-4939-2864-4_247),
in the *Encyclopedia of Algorithms*. Its Key Results section describes
Bird–Baker's 2D row-marking and KMP phases, then says to generalize to higher
dimensions by repeated application of the reduction step. This bounded 3D
profile instantiates that recursive slice-matching extension. The chapter's
description is used for algorithm attribution and method specification only;
all code, bounds, fixtures, and serialization rules are clean-room work. No
source code, prose, examples, figures, or test data were copied. See
[RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [`c/t/three_dimensional_bird_baker_matching.c`](../../../c/t/three_dimensional_bird_baker_matching.c) |
| C3 | [`c3/t/three_dimensional_bird_baker_matching.c3`](../../../c3/t/three_dimensional_bird_baker_matching.c3) |
| C++ | [`cpp/t/three_dimensional_bird_baker_matching.cpp`](../../../cpp/t/three_dimensional_bird_baker_matching.cpp) |
| Elisa | [`elisa/t/three_dimensional_bird_baker_matching.elisa`](../../../elisa/t/three_dimensional_bird_baker_matching.elisa) |
| Mojo | [`mojo/t/three_dimensional_bird_baker_matching.mojo`](../../../mojo/t/three_dimensional_bird_baker_matching.mojo) |
| Nim | [`nim/t/three_dimensional_bird_baker_matching.nim`](../../../nim/t/three_dimensional_bird_baker_matching.nim) |
| Odin | [`odin/t/three_dimensional_bird_baker_matching.odin`](../../../odin/t/three_dimensional_bird_baker_matching.odin) |
| Rust | [`rust/t/three_dimensional_bird_baker_matching.rs`](../../../rust/t/three_dimensional_bird_baker_matching.rs) |
| V | [`v/t/three_dimensional_bird_baker_matching.v`](../../../v/t/three_dimensional_bird_baker_matching.v) |
| Zig | [`zig/t/three_dimensional_bird_baker_matching.zig`](../../../zig/t/three_dimensional_bird_baker_matching.zig) |

See [workload.json](workload.json), [INVENTORY.md](INVENTORY.md), and the
callable static [workload review](verify_workload.py).
