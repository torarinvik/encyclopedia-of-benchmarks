# Signed-permutation overlap-forest components

This package isolates the overlap-forest component stage used by reversal
distance. The primary follows Bader, Moret, and Yan's two-scan construction:
expand a signed permutation relative to the identity into an unsigned
permutation, form its alternating black/gray cycle graph, label each cycle by
its smallest and largest vertex, then scan the vertex sequence while
maintaining the stack of active tree extents. When an active top has a larger
begin than the current cycle, it is popped, assigned the current cycle as
parent, and merged into the current extent. A final increasing-begin pass
propagates each forest root as a component label.

Input is the integer sequence [n,g_0,...,g_(n-1)] with 1<=n<=8. The signed
values are a permutation of 1..n by absolute value, with no zero. A positive
gene x expands to (2x-1,2x) and a negative gene to (2x,2x-1); sentinels fix
pi(0)=0 and pi(2n+1)=2n+1. The alternating cycle graph has black edges
(2i,2i+1) and gray edges (pi(2i),pi(2i+1)), for 0<=i<=n.

Output is [cycle_count,(B,E,component_root)*cycle_count], ordered by
increasing cycle begin B; all cycle vertices are included. The source removes
2-cycles because they cannot overlap any other cycle. This profile retains
them as inert singleton components, which leaves all nontrivial components
unchanged while making the output cover every cycle. component_root is the
smallest B in that component. Input is exactly n+1 signed-i64 words, with
maximum valid/parseable lengths 9/10. At most n+1=9 cycles occur, so output
is at most 28 words / 224 bytes. Malformed input returns -1; null or
undersized output returns -2 without writing. Workspace is capped at 4,096
bytes.

The independent reference constructs the overlap graph explicitly by testing
all pairs of gray-edge intervals for strict interleaving, then labels its
components by graph traversal. Its O(n^2) construction does not use the
primary's stack refinement. Both references include 2-cycle singleton labels.

The existing
[signed_permutation_reversal_sequence](../signed_permutation_reversal_sequence/README.md)
package constructs a shortest reversal sequence by bounded breadth-first
search; it does not build a breakpoint cycle graph or overlap forest. This
package measures only the component-construction stage. It does not compute
hurdles, fortresses, reversal distance, or a sorting sequence.

The Encyclopedia context is David Bader, “Sorting Signed Permutations by
Reversal (Reversal Distance),” Chapter 383, DOI
[10.1007/978-1-4939-2864-4_383](https://doi.org/10.1007/978-1-4939-2864-4_383).
The operational method is Bader, Moret, and Yan, “A Linear-Time Algorithm
for Computing Inversion Distance between Signed Permutations with an
Experimental Study,” sections 4–5 and Figure 2, DOI
[10.1089/106652701753216503](https://doi.org/10.1089/106652701753216503).
The code, fixtures, and documentation are clean-room implementations of the
mathematical procedure; no published code, tests, examples, diagrams, or prose
are copied. See [RIGHTS.md](RIGHTS.md).

[workload.json](workload.json) covers identity cycles, a signed orientation
case, interleaving cycles that merge through the stack, maximum output,
invalid signed permutations, null buffers, and capacity errors. Static
metadata and fixture/reference helpers are listed in [INVENTORY.md](INVENTORY.md).

| Language | Port |
|---|---|
| C | [signed_permutation_overlap_forest_components.c](../../../c/s/signed_permutation_overlap_forest_components.c) |
| C3 | [signed_permutation_overlap_forest_components.c3](../../../c3/s/signed_permutation_overlap_forest_components.c3) |
| C++ | [signed_permutation_overlap_forest_components.cpp](../../../cpp/s/signed_permutation_overlap_forest_components.cpp) |
| Elisa | [signed_permutation_overlap_forest_components.elisa](../../../elisa/s/signed_permutation_overlap_forest_components.elisa) |
| Mojo | [signed_permutation_overlap_forest_components.mojo](../../../mojo/s/signed_permutation_overlap_forest_components.mojo) |
| Nim | [signed_permutation_overlap_forest_components.nim](../../../nim/s/signed_permutation_overlap_forest_components.nim) |
| Odin | [signed_permutation_overlap_forest_components.odin](../../../odin/s/signed_permutation_overlap_forest_components.odin) |
| Rust | [signed_permutation_overlap_forest_components.rs](../../../rust/s/signed_permutation_overlap_forest_components.rs) |
| V | [signed_permutation_overlap_forest_components.v](../../../v/s/signed_permutation_overlap_forest_components.v) |
| Zig | [signed_permutation_overlap_forest_components.zig](../../../zig/s/signed_permutation_overlap_forest_components.zig) |

All ports use the i64_array_bytes_output ABI. Shared suite and catalog
integration remain with root.
