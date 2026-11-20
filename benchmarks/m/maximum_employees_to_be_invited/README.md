# Maximum employees to be invited

For a functional graph in which each employee points to one distinct favorite,
return the largest group that can sit in a circle with every attendee next to
their favorite. A two-person circle counts its two participants as adjacent to
each other (the previous and next seat are the same other participant).

## Contract

The exported scalar ABI symbol is `maximum_employees_to_be_invited`. Input is
`[n,favorite_0,...,favorite_(n-1)]`, with `2<=n<=8`. Each favorite is in
`[0,n)` and differs from its own employee index. The frame must contain exactly
`n+1` signed 64-bit words; a maximum-length frame with one trailing word is
accepted by the parser only to exercise invalid framing. Null, malformed,
out-of-range, or self-favorite input returns `-1`.

The maximum valid input is 9 words and the maximum parseable frame is 10 words.
Valid results are in `2..n`.

## Algorithms

The primary removes indegree-zero vertices in queue order while propagating the
longest incoming chain length to each favorite. The vertices left after this
peeling are cycles. A cycle of length at least three is a candidate by itself;
for each mutual pair, the longest incoming chain ending at either member can
extend that pair, and the extended pair components can all be combined. The
answer is the larger of the longest cycle and the sum of all extended pairs.
This takes `O(n)` time and `O(n)` space.

The independent oracle examines every attendee subset and every circular
ordering of each subset (fixing the smallest attendee first to remove rotations)
and checks the adjacency rule directly. It does not use indegree peeling or
cycle decomposition.

## Distinctness and provenance

The nearby `functional_graph_cycle_parameters` and
`functional_graph_cycle_brent` profiles measure the tail and period reached
from a specified start. They do not optimize a circular seating group or
combine incoming chains around mutual pairs. This package benchmarks that
different whole-graph objective. Algorithm provenance is the official
[LeetCode 2127 problem](https://leetcode.com/problems/maximum-employees-to-be-invited-to-a-meeting/)
and the [OI Wiki functional-graph concept](https://oi-wiki.org/graph/concept/);
only algorithm ideas and bounds are used.

See [`RIGHTS.md`](RIGHTS.md), [`workload.json`](workload.json), the two oracle
modules, and [`check_inventory.py`](check_inventory.py).

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/maximum_employees_to_be_invited.c`](../../../c/m/maximum_employees_to_be_invited.c) |
| C3 | [`c3/m/maximum_employees_to_be_invited.c3`](../../../c3/m/maximum_employees_to_be_invited.c3) |
| C++ | [`cpp/m/maximum_employees_to_be_invited.cpp`](../../../cpp/m/maximum_employees_to_be_invited.cpp) |
| Elisa | [`elisa/m/maximum_employees_to_be_invited.elisa`](../../../elisa/m/maximum_employees_to_be_invited.elisa) |
| Mojo | [`mojo/m/maximum_employees_to_be_invited.mojo`](../../../mojo/m/maximum_employees_to_be_invited.mojo) |
| Nim | [`nim/m/maximum_employees_to_be_invited.nim`](../../../nim/m/maximum_employees_to_be_invited.nim) |
| Odin | [`odin/m/maximum_employees_to_be_invited.odin`](../../../odin/m/maximum_employees_to_be_invited.odin) |
| Rust | [`rust/m/maximum_employees_to_be_invited.rs`](../../../rust/m/maximum_employees_to_be_invited.rs) |
| V | [`v/m/maximum_employees_to_be_invited.v`](../../../v/m/maximum_employees_to_be_invited.v) |
| Zig | [`zig/m/maximum_employees_to_be_invited.zig`](../../../zig/m/maximum_employees_to_be_invited.zig) |
