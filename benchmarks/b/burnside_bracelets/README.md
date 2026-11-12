# Burnside orbit count for colored bracelets

Count colorings of `N` cyclic positions up to rotations and reflections. The
benchmark applies Burnside's lemma to the dihedral action: for each of the
`2N` group elements, it counts permutation cycles and adds
`color_count^cycles` to the fixed-coloring sum. Dividing by `2N` gives the
number of distinct coloring orbits.

## Contract

Input is `[N, color_count]`, with `1 <= N <= 10` and `0 <= color_count <= 3`.
The small local profile makes the exact integer result fit comfortably in
signed 64-bit output. Zero colors yield no colorings because `N` is positive.
For `N=1` and `N=2`, the action lists all rotations and reflections even when
some induce the same permutation; Burnside's average remains valid. Output is
one signed 64-bit little-endian orbit count. Invalid input returns `-1`; null
or short output returns `-2` without writing.

## Algorithm and oracle

The ports build each rotation or reflection as an index permutation and count
its cycles by walking the permutation with a visited array. A permutation
with `c` cycles fixes exactly `color_count^c` colorings. Summing these fixed
counts and dividing by the `2N` group elements takes `O(N^2)` time and `O(N)`
temporary storage.

The independent oracle enumerates every bounded coloring, transforms it by
each dihedral action, and counts canonical orbit representatives. It does not
use Burnside averaging. The benchmark therefore exercises orbit counting,
while the oracle uses direct equivalence classes.

The algorithm reference is [CP-Algorithms: Burnside's lemma / Pólya
enumeration theorem](https://cp-algorithms.com/combinatorics/burnside.html).
This repository implements the mathematical method independently; no source
code or problem text is copied.

[`workload.json`](workload.json) includes one- through four-position actions,
the maximum local bounds, malformed arrays, and output-buffer behavior.

## Implementations

| Language | Port |
|---|---|
| C | [`c/b/burnside_bracelets.c`](../../../c/b/burnside_bracelets.c) |
| C3 | [`c3/b/burnside_bracelets.c3`](../../../c3/b/burnside_bracelets.c3) |
| C++ | [`cpp/b/burnside_bracelets.cpp`](../../../cpp/b/burnside_bracelets.cpp) |
| Elisa | [`elisa/b/burnside_bracelets.elisa`](../../../elisa/b/burnside_bracelets.elisa) |
| Mojo | [`mojo/b/burnside_bracelets.mojo`](../../../mojo/b/burnside_bracelets.mojo) |
| Nim | [`nim/b/burnside_bracelets.nim`](../../../nim/b/burnside_bracelets.nim) |
| Odin | [`odin/b/burnside_bracelets.odin`](../../../odin/b/burnside_bracelets.odin) |
| Rust | [`rust/b/burnside_bracelets.rs`](../../../rust/b/burnside_bracelets.rs) |
| V | [`v/b/burnside_bracelets.v`](../../../v/b/burnside_bracelets.v) |
| Zig | [`zig/b/burnside_bracelets.zig`](../../../zig/b/burnside_bracelets.zig) |
