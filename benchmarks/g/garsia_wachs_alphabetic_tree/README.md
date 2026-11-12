# Garsia–Wachs alphabetic tree

This package computes a minimum-cost ordered full binary tree for an ordered
sequence of leaf weights. Its cost is the weighted external path length
`sum(weight[i] * depth[i])`. It uses the Garsia–Wachs phase-and-reconstruction
method and returns the ordered leaf depths as a compact certificate. The
profile is distinct from successful-key optimal binary search trees, which
have a different interval objective and include unsuccessful gaps, and from
matrix-chain multiplication, which chooses parenthesizations for matrix
dimensions.

## Input and ABI

The exported C ABI symbol is
`garsia_wachs_alphabetic_tree(const int64_t *input, size_t length,
uint8_t *output, size_t capacity)`. It uses `i64_array_bytes_output`.

Input is the signed 64-bit integer array
`[N, weight[0], ..., weight[N-1]]`, with `1 <= N <= 64`, each weight in
`0..=1,000,000`, and exactly `N+1` words. The maximum valid input has 65
words; the maximum parseable frame has 66 words.

Output is `[minimum_cost, depth[0], ..., depth[N-1]]`, encoded as signed
64-bit little-endian words, for `8*(N+1)` bytes (at most 520). For one leaf,
the result is cost zero and depth zero. A successful call returns the number
of output bytes. Malformed input or an invalid profile returns `-1`; null or
undersized output returns `-2`. Ports stage the complete result before writing,
so errors leave output untouched.

## Algorithm and complexity

The first phase adds an implicit right infinity sentinel, repeatedly selects
the first eligible adjacent pair from the left, merges its two temporary
trees, and reinserts their parent after the nearest preceding weight at least
as large as the new weight. It records the temporary tree's leaf depths. The
second phase rebuilds an ordered full tree from those depths with a stack,
combining adjacent equal-depth subtrees. The reported cost is then the dot
product of input weights and leaf depths.

For this bounded profile, the active sequence uses fixed arrays and linear
search/insertion, so the worst-case time is `O(N^2)`. Tree traversal,
reconstruction, and staged output use `O(N)` additional storage. Zero weights
are allowed; ties are resolved by choosing the first eligible pair and by
reinserting after the nearest preceding weight greater than or equal to the
combined weight.

The primary oracle follows the phase-and-reconstruction algorithm. The
independent verifier uses interval dynamic programming to calculate the
optimum, checks the returned ordered full-tree depth certificate, and
recomputes its weighted cost.

## Sources and ports

The algorithm is based on the description in the OI Wiki
[Garsia–Wachs chapter](https://oi-wiki.org/misc/garsia-wachs/). The article is
under CC BY-SA 4.0 with SATA terms; the implementations here are clean-room
ports based on the algorithm description. See [RIGHTS.md](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/g/garsia_wachs_alphabetic_tree.c`](../../../c/g/garsia_wachs_alphabetic_tree.c) |
| C3 | [`c3/g/garsia_wachs_alphabetic_tree.c3`](../../../c3/g/garsia_wachs_alphabetic_tree.c3) |
| C++ | [`cpp/g/garsia_wachs_alphabetic_tree.cpp`](../../../cpp/g/garsia_wachs_alphabetic_tree.cpp) |
| Elisa | [`elisa/g/garsia_wachs_alphabetic_tree.elisa`](../../../elisa/g/garsia_wachs_alphabetic_tree.elisa) |
| Mojo | [`mojo/g/garsia_wachs_alphabetic_tree.mojo`](../../../mojo/g/garsia_wachs_alphabetic_tree.mojo) |
| Nim | [`nim/g/garsia_wachs_alphabetic_tree.nim`](../../../nim/g/garsia_wachs_alphabetic_tree.nim) |
| Odin | [`odin/g/garsia_wachs_alphabetic_tree.odin`](../../../odin/g/garsia_wachs_alphabetic_tree.odin) |
| Rust | [`rust/g/garsia_wachs_alphabetic_tree.rs`](../../../rust/g/garsia_wachs_alphabetic_tree.rs) |
| V | [`v/g/garsia_wachs_alphabetic_tree.v`](../../../v/g/garsia_wachs_alphabetic_tree.v) |
| Zig | [`zig/g/garsia_wachs_alphabetic_tree.zig`](../../../zig/g/garsia_wachs_alphabetic_tree.zig) |

The fixed workload is in [`workload.json`](workload.json). The primary and
independent oracle modules are
[`garsia_wachs_alphabetic_tree_oracle.py`](../../garsia_wachs_alphabetic_tree_oracle.py)
and
[`garsia_wachs_alphabetic_tree_verifier_oracle.py`](../../garsia_wachs_alphabetic_tree_verifier_oracle.py).
The benchmark is registered in the shared byte-output runner and verifier,
which also prepares maximum-size profiles and checks certificates with the
independent interval-DP verifier.
