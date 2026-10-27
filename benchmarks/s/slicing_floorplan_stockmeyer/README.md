# Stockmeyer slicing-floorplan orientation

This profile minimizes floorplan area for a supplied slicing tree by dynamic
programming over nondominated `(height,width)` pairs. A leaf cell contributes
its two possible orientations. A vertical internal node combines child pairs
as `(max(child heights), sum(child widths))`; a horizontal node combines them
as `(sum(child heights), max(child widths))`. Each subtree retains its
nondominated dimension skyline and an orientation backpointer. At the root,
the profile minimizes area, then height, width, and the leaf-orientation bit
vector in that order.

Input is `[leaf_count,postorder_tokens...]`. Token `2` introduces a leaf and
is followed by its positive `(height,width)` dimensions; token `0` combines
two postfix subtrees with a vertical slice, and token `1` combines them with a
horizontal slice. There are at most eight leaves and each side is at most 20.
The caller supplies the chapter's smallest-depth, nonredundant slicing tree;
ports check the nonredundant rule that an internal node differs from its right
internal child, but do not search for equivalent tree representations.

The bounded implementation considers every pair from the two child skylines
and prunes dominated results. This preserves the chapter's Stockmeyer DP
recurrence while using a direct bounded merge; it does not claim the chapter's
`O(n d)` two-pointer running time. The output is four little-endian signed
64-bit values: `[area,height,width,orientation_mask]`. Bit `i` is zero when
leaf `i` keeps its supplied dimensions and one when it rotates. Malformed
input returns `-1`; a null output or capacity below 32 bytes returns `-2`
without writing.

The primary oracle uses subtree skylines and backpointers. The independent
verifier enumerates every orientation mask and evaluates the supplied tree.
The [workload](workload.json) covers vertical and horizontal cuts, a nested
tie, eight leaves, and malformed/capacity cases.

Source: Evangeline F. Y. Young, “Slicing Floorplan Orientation,”
*Encyclopedia of Algorithms*, DOI
[`10.1007/978-1-4939-2864-4_379`](https://doi.org/10.1007/978-1-4939-2864-4_379).
See [RIGHTS.md](RIGHTS.md) for attribution.

| Language | Port |
|---|---|
| C | `c/s/slicing_floorplan_stockmeyer.c` |
| C3 | `c3/s/slicing_floorplan_stockmeyer.c3` |
| C++ | `cpp/s/slicing_floorplan_stockmeyer.cpp` |
| Elisa | `elisa/s/slicing_floorplan_stockmeyer.elisa` |
| Nim | `nim/s/slicing_floorplan_stockmeyer.nim` |
| Odin | `odin/s/slicing_floorplan_stockmeyer.odin` |
| Rust | `rust/s/slicing_floorplan_stockmeyer.rs` |
| V | `v/s/slicing_floorplan_stockmeyer.v` |
| Zig | `zig/s/slicing_floorplan_stockmeyer.zig` |
