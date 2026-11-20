# Greedy minimum interval cover

This package measures the greedy algorithm for choosing the smallest subset
of supplied intervals that covers a target interval. At each uncovered
frontier, choose an eligible interval that reaches furthest to the right.

## Contract

The ABI is `i64_array_scalar`; the package id and exported symbol are
`interval_cover`. Input is `[target_left, target_right, n, left_0, right_0,
...]`, with `0<=target_left<=target_right<=32`, `0<=n<=16`, and each supplied
interval satisfying `0<=left_i<right_i<=32`. All intervals and the target use
half-open semantics `[left,right)`. The exact input length is `3+2*n`.
Invalid or null input returns `-2`; valid but uncoverable targets return
`-1`. An empty target returns `0`.

The scalar result is the minimum number of selected intervals. Duplicate
intervals are allowed as distinct choices. The maximum valid frame contains
35 integers; implementations accept one additional parseable integer to
reject trailing data. The workload includes a 36-value parseable-boundary
frame with trailing data.

## Algorithm and distinction

Starting at `target_left`, scan the supplied intervals and choose the interval
whose left endpoint is at or before the current frontier and whose right
endpoint is furthest ahead. If no interval advances the frontier, the target
has a gap. Otherwise repeat until the frontier reaches `target_right`. The
farthest-reaching choice is safe because any feasible cover must cross the
current frontier, and replacing its next interval with one reaching at least
as far cannot increase the remaining work. Repeated candidate scans take
`O(n^2)` time and `O(1)` auxiliary space in this bounded profile.

This differs from [`merge_intervals`](../../merge_intervals/README.md), which
constructs the union of all input intervals, and from
[`weighted_interval_scheduling`](../../w/weighted_interval_scheduling/README.md),
which selects a high-value non-overlapping schedule. Here the objective is to
cover a specified target with the fewest supplied intervals. The independent
oracle checks all subsets against the target's unit cells.

## Sources and ports

The candidate comes from KACTL's [IntervalCover entry](https://github.com/kth-competitive-programming/kactl/blob/main/content/various/IntervalCover.h)
in its [various chapter index](https://raw.githubusercontent.com/kth-competitive-programming/kactl/main/content/various/chapter.tex).
The greedy rule is also described in Sean McIntyre's NYU
[CSCI-UA.0380 class notes](https://cs.nyu.edu/courses/summer13/CSCI-UA.0380-001/slides/Class05.pdf).
Only algorithm ideas are used; all code, fixtures, and prose here are
independently authored. See [`RIGHTS.md`](RIGHTS.md).

| Language | Port |
|---|---|
| C | [`c/i/interval_cover.c`](../../../c/i/interval_cover.c) |
| C3 | [`c3/i/interval_cover.c3`](../../../c3/i/interval_cover.c3) |
| C++ | [`cpp/i/interval_cover.cpp`](../../../cpp/i/interval_cover.cpp) |
| Elisa | [`elisa/i/interval_cover.elisa`](../../../elisa/i/interval_cover.elisa) |
| Mojo | [`mojo/i/interval_cover.mojo`](../../../mojo/i/interval_cover.mojo) |
| Nim | [`nim/i/interval_cover.nim`](../../../nim/i/interval_cover.nim) |
| Odin | [`odin/i/interval_cover.odin`](../../../odin/i/interval_cover.odin) |
| Rust | [`rust/i/interval_cover.rs`](../../../rust/i/interval_cover.rs) |
| V | [`v/i/interval_cover.v`](../../../v/i/interval_cover.v) |
| Zig | [`zig/i/interval_cover.zig`](../../../zig/i/interval_cover.zig) |

[`workload.json`](workload.json) includes greedy-choice, empty-target,
impossible-gap, maximum-size, and invalid-frame cases.
[`verify_workload.py`](verify_workload.py) provides static fixture and
source-inventory review; it has not been run.
