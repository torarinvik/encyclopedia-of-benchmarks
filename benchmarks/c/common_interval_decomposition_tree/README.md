# Common Interval Decomposition Tree

This package constructs the strong-interval decomposition tree of one
permutation. It follows the Library Checker task's definitions of connected
intervals, strong intervals, the inclusion Hasse tree, and linear versus prime
nodes. A node is prime exactly when some consecutive group of its children
does not form a connected interval.

## Bounded contract

The ABI is `i64_array_bytes_output`. Input is
`[n, P_0, ..., P_(n-1)]`, where `1 <= n <= 48` and the remaining values are a
permutation of `0..n-1`. Output is a little-endian signed-64 vector
`[X, parent_0, left_0, right_0, type_0, ...]`, where intervals use inclusive
zero-based positions, `parent=-1` denotes the root, and `type=0` means linear
while `type=1` means prime. Nodes are ordered by decreasing interval length,
then increasing left endpoint, so every parent index precedes its children.
Malformed input returns `-1`; a null or undersized output buffer returns `-2`
without writes. The maximum parseable input length is 49 i64 values and the
maximum output is 3,048 bytes, using the strong-interval bound `X <= 2n-1`.

The ports use a bounded exhaustive construction: enumerate all connected
intervals, mark any interval that overlaps another connected interval as
non-strong, connect the remaining intervals by nearest strict containment,
and classify each node by checking consecutive child unions. Its worst-case
time is `O(n^4)` and auxiliary storage is `O(n^2)`. This is intentionally a
small exact profile, not the official-scale linear-time permutation-tree
construction.

## Independent checking

`common_interval_decomposition_tree_oracle.py` uses explicit value sets for
connectedness, constructs the expected serialized tree, and exposes a
certificate validator that checks the emitted strong intervals, Hasse parent
links, and node labels independently of port ordering. The workload includes
small pinned ABI cases plus identity, reverse, prime-root, nested, and maximum
size input profiles.

The ten ports are in `c/c`, `c3/c`, `cpp/c`, `elisa/c`, `mojo/c`, `nim/c`,
`odin/c`, `rust/c`, `v/c`, and `zig/c`.

## Provenance and rights

The task semantics and output fields come from the [Library Checker problem
statement](https://github.com/yosupo06/library-checker-problems/blob/master/tree/common_interval_decomposition_tree/task.md).
The strong-interval decomposition context is described by Binh-Minh Bui Xuan,
Michel Habib, and Christophe Paul, [“Revisiting T. Uno and M. Yagiura’s
Algorithm,” ISAAC 2005, DOI
10.1007/11602613_16](https://doi.org/10.1007/11602613_16). The ports are
clean-room implementations derived from these definitions; no upstream source
code is included. See `RIGHTS.md` for attribution details.
