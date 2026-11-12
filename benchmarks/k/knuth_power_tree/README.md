# Knuth power tree

Build the deterministic shared power tree through a requested positive
exponent and return its first-discovery path. Each child exponent is the sum
of its parent and one earlier exponent on that parent's path. This tree is a
way to obtain an addition chain; it does not promise a shortest chain.

## Contract

The exported C ABI symbol is
`knuth_power_tree(const int64_t *input, size_t length, uint8_t *output,
size_t capacity)` in the `i64_array_bytes_output` family.

Input is exactly `[target]`, where `1 <= target <= 127`. Output is a sequence
of signed 64-bit little-endian words `[multiplication_count, exponent_0, ...,
exponent_last]`. The path begins at 1 and ends at `target`; target 1 has zero
multiplications and path `[1]`. A successful call returns the byte count,
`-1` means malformed or out-of-profile input, and `-2` means a null output
pointer or insufficient capacity. Errors leave output untouched. The maximum
output is 1,024 bytes.

The bounded profile stops considering candidate sums above `target`. Such
labels cannot be ancestors of a smaller requested exponent because all
addends are positive; omitting them preserves every first-discovery path at or
below the target.

## Algorithm and complexity

The tree begins at exponent 1. Nodes are expanded in breadth-first discovery
order. For each node, its path is visited from root to node and each path
exponent is added to the node label. Sums above the target and labels already
present in the global tree are skipped. The first new occurrence of `target`
defines its parent and returned path. The generated chain can be longer than
an optimal addition chain; for example, the workload includes target 77 to
keep this property visible.

For target bound `T`, at most `T` positive labels are stored. Each expansion
examines at most `T` ancestors, so time is `O(T^2)` and auxiliary storage is
`O(T)`. The primary oracle uses a parent map and FIFO queue. The independent
verifier stores explicit paths by BFS level, checks each addition-chain step,
and requires the same deterministic first-discovery path.

This is distinct from [`problem122`](../problem122/README.md), which searches
minimum-length star addition chains for each target and returns their length
sum. The Knuth tree shares discoveries across targets and can be suboptimal.

## Workload and files

[`workload.json`](workload.json) includes small exact path fixtures, malformed
inputs, output-capacity failures, target 77, and the maximum target. The
oracles are [`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py).
[`verify_workload.py`](verify_workload.py) is a static inventory and fixture
checker; it does not launch language ports.

## Implementations

| Language | Source |
|---|---|
| C | [`c/k/knuth_power_tree.c`](../../../c/k/knuth_power_tree.c) |
| C3 | [`c3/k/knuth_power_tree.c3`](../../../c3/k/knuth_power_tree.c3) |
| C++ | [`cpp/k/knuth_power_tree.cpp`](../../../cpp/k/knuth_power_tree.cpp) |
| Elisa | [`elisa/k/knuth_power_tree.elisa`](../../../elisa/k/knuth_power_tree.elisa) |
| Mojo | [`mojo/k/knuth_power_tree.mojo`](../../../mojo/k/knuth_power_tree.mojo) |
| Nim | [`nim/k/knuth_power_tree.nim`](../../../nim/k/knuth_power_tree.nim) |
| Odin | [`odin/k/knuth_power_tree.odin`](../../../odin/k/knuth_power_tree.odin) |
| Rust | [`rust/k/knuth_power_tree.rs`](../../../rust/k/knuth_power_tree.rs) |
| V | [`v/k/knuth_power_tree.v`](../../../v/k/knuth_power_tree.v) |
| Zig | [`zig/k/knuth_power_tree.zig`](../../../zig/k/knuth_power_tree.zig) |

See [RIGHTS.md](RIGHTS.md) for provenance and attribution.
