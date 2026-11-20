# Minimum cost to merge stones

Given an ordered row of stone piles and a merge arity `k`, repeatedly merge
exactly `k` consecutive piles into one. The cost of a merge is the sum of those
piles. Return the minimum total cost to reduce the row to one pile, or `-1` if
that cannot be done.

## Contract

The `i64_array_scalar` input is `[n,k,stones_0,...,stones_(n-1)]`. The bounds
match LeetCode 1000: `1<=n<=30`, `2<=k<=30`, and each pile weight is in
`[1,100]`. Input framing is exact: maximum valid length 32 and maximum
parseable length 33, which admits one trailing-word probe. Return the minimum
total merge cost, in `[-1,87000]`. Null, malformed, out-of-range, and
impossible inputs return `-1`.

Every merge reduces the pile count by `k-1`, so a final single pile is possible
only when `(n-1) % (k-1) == 0`. The primary uses interval states
`dp[left][right][piles]`: the minimum cost to reduce that interval to exactly
`piles` piles. For two or more remaining piles, split the interval into a left
part reduced to one pile and a right part reduced to `piles-1`; for one pile,
first reduce to exactly `k` piles and then pay the interval sum. Processing
short intervals first gives `O(n^3 k)` time and `O(n^2 k)` state.

The independent reference stores one value per interval: the minimum cost to
reduce it to the residue-determined minimum possible pile count. Its split
positions advance by `k-1`, and it adds the interval sum precisely when the
interval can become one pile. This separate state recurrence takes `O(n^3)`
time and `O(n^2)` space.

## Source and overlap check

The [official LeetCode 1000 statement](https://leetcode.com/problems/minimum-cost-to-merge-stones/)
defines the consecutive `k`-pile operation, merge cost, result, and bounds. The
ports and both DP recurrences are clean-room descriptions of that problem.
Local package-name and README searches found no existing minimum-cost pile
merge profile. [`matrix_chain_multiplication`](../matrix_chain_multiplication/README.md)
minimizes scalar multiplication counts for matrix parenthesization; ordinary
optimal merge/Huffman-style profiles, where present, do not constrain merges to
consecutive intervals with fixed arity.

See [`workload.json`](workload.json), [`RIGHTS.md`](RIGHTS.md),
[`INVENTORY.md`](INVENTORY.md), and the static [`check_inventory.py`](check_inventory.py).
The inventory helper has not been run.

## Language ports

| Language | Source |
|---|---|
| C | [`c/m/minimum_cost_to_merge_stones.c`](../../../c/m/minimum_cost_to_merge_stones.c) |
| C3 | [`c3/m/minimum_cost_to_merge_stones.c3`](../../../c3/m/minimum_cost_to_merge_stones.c3) |
| C++ | [`cpp/m/minimum_cost_to_merge_stones.cpp`](../../../cpp/m/minimum_cost_to_merge_stones.cpp) |
| Elisa | [`elisa/m/minimum_cost_to_merge_stones.elisa`](../../../elisa/m/minimum_cost_to_merge_stones.elisa) |
| Mojo | [`mojo/m/minimum_cost_to_merge_stones.mojo`](../../../mojo/m/minimum_cost_to_merge_stones.mojo) |
| Nim | [`nim/m/minimum_cost_to_merge_stones.nim`](../../../nim/m/minimum_cost_to_merge_stones.nim) |
| Odin | [`odin/m/minimum_cost_to_merge_stones.odin`](../../../odin/m/minimum_cost_to_merge_stones.odin) |
| Rust | [`rust/m/minimum_cost_to_merge_stones.rs`](../../../rust/m/minimum_cost_to_merge_stones.rs) |
| V | [`v/m/minimum_cost_to_merge_stones.v`](../../../v/m/minimum_cost_to_merge_stones.v) |
| Zig | [`zig/m/minimum_cost_to_merge_stones.zig`](../../../zig/m/minimum_cost_to_merge_stones.zig) |
