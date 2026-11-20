# JSort

JSort partially orders an array with two heap-construction passes, then
finishes it with insertion sort. Following the NIST DADS definition, the
first pass builds a min-heap over the full array, placing a least item at the
front. The second pass reverses the array, builds a max-heap, then reverses
the array back, placing a greatest item at the end. A final ascending
insertion sort completes the ordering. The implementation is in place and
does not promise stability.

The `sort_call` ABI sorts zero through 1,024 signed 64-bit values in place.
Duplicates are retained. The workload contains modular-affine timing inputs
and semantic fixtures for empty, ordered, reverse-ordered, equal, duplicate,
two-run, heap-shaped, and signed-boundary arrays. The primary independent
oracle is a bottom-up mergesort; a separate built-in-sort reference checks
each published fixture.

The NIST DADS JSort entry was modified 19 January 2021 and accessed on
2026-11-16. It links [Pat Morin's Java implementation](https://cglab.ca/~morin/misc/sortalg/JSortAlgorithm.java),
which is listed in [Morin's source index](https://cglab.ca/~morin/misc/sortalg/).
The ports implement the algorithm description without copying source code.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/j/jsort.c`](../../../c/j/jsort.c) |
| C3 | [`c3/j/jsort.c3`](../../../c3/j/jsort.c3) |
| C++ | [`cpp/j/jsort.cpp`](../../../cpp/j/jsort.cpp) |
| Elisa | [`elisa/j/jsort.elisa`](../../../elisa/j/jsort.elisa) |
| Mojo | [`mojo/j/jsort.mojo`](../../../mojo/j/jsort.mojo) |
| Nim | [`nim/j/jsort.nim`](../../../nim/j/jsort.nim) |
| Odin | [`odin/j/jsort.odin`](../../../odin/j/jsort.odin) |
| Rust | [`rust/j/jsort.rs`](../../../rust/j/jsort.rs) |
| V | [`v/j/jsort.v`](../../../v/j/jsort.v) |
| Zig | [`zig/j/jsort.zig`](../../../zig/j/jsort.zig) |

Sources: [NIST DADS JSort entry](https://xlinux.nist.gov/dads/HTML/JSort.html)
and [Morin's sorting-source index](https://cglab.ca/~morin/misc/sortalg/).
