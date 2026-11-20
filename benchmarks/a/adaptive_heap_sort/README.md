# Adaptive Heapsort

Adaptive Heapsort builds a min Cartesian tree whose in-order traversal is the
input sequence, then keeps only the roots of unreported subtrees in a binary
min-heap. It repeatedly removes the least candidate, writes that value to the
output buffer, and adds its Cartesian-tree children as new candidates. Every
remaining value is below a frontier node in the tree, so the heap contains all
possible next minima without holding every unreported value.
Cartesian-tree construction is linear. The standard binary-heap frontier
requires `O(n log n)` time in the worst case, and its size adapts to the
existing order in the input.

The NIST DADS entry describes the candidate structure as a randomized binary
search tree (RBST). The detailed Levcopoulos–Petersson description and the
2024 paper *Fast and Simple Sorting Using Partial Information* specify a
deterministic min Cartesian tree followed by a standard heap over its
frontier. These ports follow that detailed LP93 method attributed by DADS;
the frontier-heap role matches DADS's candidate-selection summary. The package
records this source-description mismatch in [`RIGHTS.md`](RIGHTS.md).

The bounded `sort_call` ABI sorts zero through 1,024 signed 64-bit values and
writes the sorted sequence back to the input array. Duplicate priorities use
the original array index as a deterministic
tie-break, matching a leftmost-minimum Cartesian-tree construction and
preserving input order among equal values. The LP93 analysis assumes distinct
keys; this tie rule extends the bounded profile to duplicates. Inputs above
1,024 elements are outside the contract and are left unchanged. The
implementation uses fixed-capacity local arrays for two tree-child links,
the construction stack, the candidate heap, and the output buffer: 40,960
bytes for five 1,024-element arrays of 64-bit values/indices.

The workload covers empty, singleton, ordered, reverse-ordered, equal,
duplicate-heavy, alternating-extreme, and partially ordered inputs. The
primary independent reference is bottom-up mergesort; a separate built-in
ordering reference checks the published fixtures. The algorithm differs from
ordinary in-place [`heap_sort`](../../h/heap_sort/README.md),
[`weak_heapsort`](../../w/weak_heapsort/README.md),
[`smooth_sort`](../../s/smooth_sort/README.md), and
[`adaptive_merge_sort`](adaptive_merge_sort/README.md): it builds an
input-order Cartesian tree and heap-orders only the eligible frontier.
[`cartesian_tree`](../../c/cartesian_tree/README.md) constructs a tree but does
not emit a sorted sequence; [`tree_sort`](../../t/tree_sort/README.md) uses an
ordinary search tree rather than this Cartesian-tree frontier.

The custom verifier is [`benchmarks/verify_adaptive_heap_sort.py`](../../verify_adaptive_heap_sort.py).
The static package checker is [`verify_workload.py`](verify_workload.py). Both
are authored but have not been run.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/adaptive_heap_sort.c`](../../../c/a/adaptive_heap_sort.c) |
| C3 | [`c3/a/adaptive_heap_sort.c3`](../../../c3/a/adaptive_heap_sort.c3) |
| C++ | [`cpp/a/adaptive_heap_sort.cpp`](../../../cpp/a/adaptive_heap_sort.cpp) |
| Elisa | [`elisa/a/adaptive_heap_sort.elisa`](../../../elisa/a/adaptive_heap_sort.elisa) |
| Mojo | [`mojo/a/adaptive_heap_sort.mojo`](../../../mojo/a/adaptive_heap_sort.mojo) |
| Nim | [`nim/a/adaptive_heap_sort.nim`](../../../nim/a/adaptive_heap_sort.nim) |
| Odin | [`odin/a/adaptive_heap_sort.odin`](../../../odin/a/adaptive_heap_sort.odin) |
| Rust | [`rust/a/adaptive_heap_sort.rs`](../../../rust/a/adaptive_heap_sort.rs) |
| V | [`v/a/adaptive_heap_sort.v`](../../../v/a/adaptive_heap_sort.v) |
| Zig | [`zig/a/adaptive_heap_sort.zig`](../../../zig/a/adaptive_heap_sort.zig) |

Sources: [NIST DADS Adaptive Heap Sort](https://xlinux.nist.gov/dads/HTML/adaptiveHeapSort.html),
Levcopoulos and Petersson, [*Adaptive Heapsort*](https://doi.org/10.1006/jagm.1993.1021),
and Haeupler et al., [*Fast and Simple Sorting Using Partial Information*](https://arxiv.org/abs/2404.04552).
