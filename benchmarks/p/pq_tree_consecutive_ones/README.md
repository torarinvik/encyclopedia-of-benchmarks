# PQ Tree for Consecutive Ones

This benchmark incrementally maintains the full family of column orders in which every input row forms one contiguous interval. It returns a reduced PQ tree, so the output describes every valid frontier rather than one witness.

## Contract

- Input is `[n, m, row_mask_0, ..., row_mask_(m-1)]`, with `2 <= n <= 20`, `0 <= m <= 32`, and each mask in `[0, 2^n)`. Bit `j` marks column `j` in that row.
- A P node allows every permutation of its children. A Q node allows its child order and its reversal. Leaves identify the original columns.
- Output is little-endian signed 64-bit words `[status, frontier_count, node_count, (kind, arg)*]` in prefix preorder. Status `1` means satisfiable; `0` means no order exists and is encoded as `[0,0,0]`.
- Node kinds are leaf `0` (argument is column id), P `1` (argument is arity), and Q `2` (argument is arity). P children are sorted by recursive encoding; Q orientation is the lexicographically smaller recursive encoding. Unary nodes are removed and Q nodes of degree two become P nodes.
- The maximum output has `3 + 2(2n-1) = 81` words, or 648 bytes. A P node of degree `k` contributes `k!` frontier orders; a Q node of degree at least three contributes two orientations.
- Malformed input returns `-1`. For valid input, null or short output returns `-2` without writes. Input validation takes precedence.

## Reduction and bounds

The primary implementation starts with one P root and one leaf per column. For each row it colors leaves by membership, derives internal colors, and applies top-down P, Q, and split templates to preserve exactly those represented orders where the marked leaves form an interval. The method follows the PQ-tree reduction approach described by [OI Wiki](https://oi-wiki.org/ds/pq-tree/) and the original [Booth–Lueker paper](https://doi.org/10.1016/S0022-0000(76)80045-1); the source is used for method attribution only.

Every normalized tree with `n` leaves has at most `2n-1` nodes because each internal node has at least two children. During one reduction, an existing node is handled by either a Work template or a split template, not both. Each such P-node template creates at most two nodes, so the transient high-water bound is `39 + 2*39 = 117` nodes at `n=20`. The fixed arena has 128 slots and recycles deleted nodes between reductions. The ports stage output before writing it. Their fixed tree arena, color/free-id arrays, reduction scratch, output staging, and counting/serialization buffers fit within the 16 KiB workspace cap.

The bounded top-down profile uses `O(nm)` work: it recolors and reduces a tree of at most `2n-1` live nodes for each of at most 32 rows. Input masks make each leaf-color assignment constant time.

## Workload and independent oracle

[`workload.json`](workload.json) includes structural profiles for an unconstrained 20-column P root, two independent 10-column Q blocks, a 16-column Q core with four free columns, an unsatisfiable three-pair cycle, and a white sibling around a single mixed child. The last case checks that a P node recurses into its sole mixed child when no pure black sibling needs to join its interval. Smaller cases exercise reversal classification and empty constraints, followed by protocol errors.

[`primary_oracle.py`](primary_oracle.py) performs incremental reductions. [`independent_oracle.py`](independent_oracle.py) enumerates all frontiers for `n <= 8`, intersects their interval sets to derive strong intervals, and classifies each node from its complete set of child orders. This provides byte-for-byte family-tree comparisons without using reduction templates. [`verify_workload.py`](verify_workload.py) checks workload bounds, the stored structural expectations, oracle agreement, and the presence of all ten source drafts. It is a static package check and is not part of the benchmark call.

## Implementations

The ten source drafts are under `c/p/`, `c3/p/`, `cpp/p/`, `elisa/p/`, `mojo/p/`, `nim/p/`, `odin/p/`, `rust/p/`, `v/p/`, and `zig/p/`.
