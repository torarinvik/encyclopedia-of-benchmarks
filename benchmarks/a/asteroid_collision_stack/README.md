# Asteroid collision by survivor stack

This profile processes signed one-dimensional asteroid sizes in input order.
Positive values move right, negative values move left, and absolute value is
magnitude. A collision is possible only when a positive survivor is directly
to the left of a negative incoming asteroid. The smaller magnitude disappears;
equal magnitudes remove both. All other neighboring directions pass without a
collision. Surviving values retain their original order.

## Contract

- ABI: `i64_array_bytes_output`, symbol `asteroid_collision_stack`.
- Input is `[n, size_0, ..., size_(n-1)]`, with `0 <= n <= 64`, exact frame
  length `n+1`, and each size in `[-127,-1]` or `[1,127]`.
- Valid and maximum parseable input lengths are 65 and 66 i64 words. The
  66-word frame is parseable for safe rejection but is invalid because it has
  an extra trailing word.
- Output is a survivor-count byte followed by signed two's-complement survivor
  bytes in input order. The largest output is 65 bytes.
- Malformed input returns `-1` before output validation. A null output pointer
  or insufficient capacity returns `-2`. Errors write no output bytes.
- The largest native scratch array is 64 i64 values (512 bytes); caller input
  and output buffers are excluded from that workspace bound.

The primary reference uses the arrival-order stack, which runs in O(n) time and
O(n) workspace. The independent reference repeatedly finds the leftmost
positive/negative adjacent pair and applies the local collision rule, taking
O(n²) time and O(n) workspace. The two methods encode the same collision
semantics with different traversals.

## Provenance and duplicate review

LeetCode's public **Asteroid Collision** title is a discovery pointer only; see
[`RIGHTS.md`](RIGHTS.md). The bounded contract and fixtures are written
independently. This is distinct from the repository's `elastic_collision2_d`,
which models physical two-dimensional elastic impacts, and from generic stack
benchmarks, which do not perform direction-dependent collision resolution.

The separate `unique_subsequences_count` profile is not an asteroid-collision
duplicate. A title-only Library Checker candidate, [Number of Subsequences](https://github.com/yosupo06/library-checker-problems/blob/master/enumerative_combinatorics/number_of_subsequences/task.md),
is already covered by that local distinct-nonempty-subsequence recurrence and
is recorded as a duplicate in the expansion ledger.

## Workload

[`workload.json`](workload.json) pins directionality, all three magnitude
outcomes, cascading removals, invalid framing, null/capacity handling, and the
maximum valid and parseable input boundaries. Expected bytes are hand-specified
and reconciled by the package's two references in the static workload helper.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/a/asteroid_collision_stack.c`](../../../c/a/asteroid_collision_stack.c) |
| C3 | [`c3/a/asteroid_collision_stack.c3`](../../../c3/a/asteroid_collision_stack.c3) |
| C++ | [`cpp/a/asteroid_collision_stack.cpp`](../../../cpp/a/asteroid_collision_stack.cpp) |
| Elisa | [`elisa/a/asteroid_collision_stack.elisa`](../../../elisa/a/asteroid_collision_stack.elisa) |
| Mojo | [`mojo/a/asteroid_collision_stack.mojo`](../../../mojo/a/asteroid_collision_stack.mojo) |
| Nim | [`nim/a/asteroid_collision_stack.nim`](../../../nim/a/asteroid_collision_stack.nim) |
| Odin | [`odin/a/asteroid_collision_stack.odin`](../../../odin/a/asteroid_collision_stack.odin) |
| Rust | [`rust/a/asteroid_collision_stack.rs`](../../../rust/a/asteroid_collision_stack.rs) |
| V | [`v/a/asteroid_collision_stack.v`](../../../v/a/asteroid_collision_stack.v) |
| Zig | [`zig/a/asteroid_collision_stack.zig`](../../../zig/a/asteroid_collision_stack.zig) |

No programs, tests, scripts, checkers, builds, compilers, profilers, or
benchmarks were run while drafting this package.
