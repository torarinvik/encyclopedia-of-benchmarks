# Odd/even jump reachability count

Count the starting indices whose deterministic alternating value-successor
path reaches the final array position. On an odd turn, select the right-side
element with the least value at least the current value; on an even turn,
select the right-side element with the greatest value at most the current
value. Equal candidate values choose the earliest index. The final position
is reachable without taking another jump.

## Contract

The `i64_array_scalar` input is `[n, values...]`, with `1 <= n <= 64`, exactly
`n` values, and each value in `[-1,000,000,1,000,000]`. Return the number of
starting indices that reach index `n-1`; malformed frames return `-1`.

The primary sorts indices in ascending and descending value order, uses a
monotone stack to assign next odd/even destinations, and evaluates the two
alternating reachability states from right to left. Its insertion sorts make
the total time O(n²); the stack passes and dynamic program take O(n). The
independent reference finds successors with direct suffix scans and simulates
every start, also taking O(n²) time. Both use O(n) auxiliary space. Maximum
valid and parseable input lengths are 65 and 66 i64 words. Native ports have a
4,096-byte auxiliary-workspace cap; at n=64 the fixed arrays account for 2,176
bytes under 64-bit index sizing, with the remaining allowance covering scalar
locals, alignment, and return temporaries. The Python reference's dynamic
allocator bytes are outside that native cap. Input storage is excluded.

The [LeetCode title page](https://leetcode.com/problems/odd-even-jump/) is a
discovery source only. The algorithm idea is cross-checked with independent
[Tam Nguyen notes](https://tamnd.github.io/brain/practice/leetcode/old/09/0975/).
No task content, examples, code, or tests are used; see [`RIGHTS.md`](RIGHTS.md).

## Duplicate review

[`next_greater_nodes`](../n/next_greater_nodes/README.md) and
[`next_smaller_element`](../n/next_smaller_element/README.md) return local
successor relations. [`jump_game`](../j/jump_game/README.md) and
[`jump_game_ii`](../j/jump_game_ii/README.md) use input-defined jump distances.
None combines value-selected alternating transitions with a two-state
reachability count.

## Implementations

| Language | Source |
|---|---|
| C | [`c/o/odd_even_jump_reachability_count.c`](../../../c/o/odd_even_jump_reachability_count.c) |
| C3 | [`c3/o/odd_even_jump_reachability_count.c3`](../../../c3/o/odd_even_jump_reachability_count.c3) |
| C++ | [`cpp/o/odd_even_jump_reachability_count.cpp`](../../../cpp/o/odd_even_jump_reachability_count.cpp) |
| Elisa | [`elisa/o/odd_even_jump_reachability_count.elisa`](../../../elisa/o/odd_even_jump_reachability_count.elisa) |
| Mojo | [`mojo/o/odd_even_jump_reachability_count.mojo`](../../../mojo/o/odd_even_jump_reachability_count.mojo) |
| Nim | [`nim/o/odd_even_jump_reachability_count.nim`](../../../nim/o/odd_even_jump_reachability_count.nim) |
| Odin | [`odin/o/odd_even_jump_reachability_count.odin`](../../../odin/o/odd_even_jump_reachability_count.odin) |
| Rust | [`rust/o/odd_even_jump_reachability_count.rs`](../../../rust/o/odd_even_jump_reachability_count.rs) |
| V | [`v/o/odd_even_jump_reachability_count.v`](../../../v/o/odd_even_jump_reachability_count.v) |
| Zig | [`zig/o/odd_even_jump_reachability_count.zig`](../../../zig/o/odd_even_jump_reachability_count.zig) |

`check_inventory.py` statically checks the ten source paths and inventory;
`verify_workload.py` reconciles pinned fixture outputs with both references.
