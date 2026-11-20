# Dynamic interval container

This benchmark maintains the union of half-open intervals under online add and
remove operations. Intervals are represented as sorted, disjoint ranges; adding
merges overlapping and adjacent ranges, and removing subtracts the requested
range from every intersecting range. This is a dynamic set operation, distinct
from the batch [`merge_intervals`](../../merge_intervals/README.md) profile,
which sorts and merges one input list without subsequent updates. It is also
distinct from [`interval_cover`](../interval_cover/README.md), which selects
the fewest supplied intervals to cover a fixed target.

## Contract

The ABI is `i64_array_scalar`, exported symbol `interval_container`. Input is
`[Q, (opcode, L, R)*Q]`, with at most 24 operations. The domain consists of
the 32 unit cells `[0,1), ... [31,32)`, and every operation must satisfy
`0 <= L <= R <= 32`. Opcode 0 adds `[L,R)`; opcode 1 removes `[L,R)`. Empty
ranges are valid no-ops. The container starts empty. The result after each
operation is the number of covered unit cells, and the scalar result is the sum
of that count multiplied by the operation's one-based index. Invalid input
returns `-1`.

The exact input length is `1 + 3*Q`: 73 values is the maximum valid frame and
74 values is the maximum parseable malformed frame. The checksum is at most
`32 * (1 + ... + 24) = 9,600`; the maximum fixture reaches this bound. The
primary implementation keeps a canonical sorted interval list. Each update
scans and rebuilds at most 24 ranges, so an update and a complete trace take
O(Q) and O(Q²) time respectively, with O(Q) auxiliary space.

## Oracles and workload

[primary_oracle.py](primary_oracle.py) applies additions and removals to a
canonical interval list. [independent_oracle.py](independent_oracle.py) uses a
32-cell boolean bitmap instead. [workload.json](workload.json) covers overlap,
adjacency, splitting, rejoining, empty ranges, absent removals, invalid frames,
null input, and the maximum valid and parseable lengths. The
[static inventory checker](verify_workload.py) reviews file and fixture
metadata; it has not been run.

## Provenance

The interval-container idea follows KACTL's [`IntervalContainer.h`](https://github.com/kth-competitive-programming/kactl/blob/main/content/various/IntervalContainer.h), which describes add/remove operations on disjoint half-open intervals and declares the source CC0. This package uses the algorithmic idea only and contains independently written code, fixtures, and documentation; no KACTL source or prose was copied. See [RIGHTS.md](RIGHTS.md).

| Language | Source |
|---|---|
| C | [c/i/interval_container.c](../../../c/i/interval_container.c) |
| C3 | [c3/i/interval_container.c3](../../../c3/i/interval_container.c3) |
| C++ | [cpp/i/interval_container.cpp](../../../cpp/i/interval_container.cpp) |
| Elisa | [elisa/i/interval_container.elisa](../../../elisa/i/interval_container.elisa) |
| Mojo | [mojo/i/interval_container.mojo](../../../mojo/i/interval_container.mojo) |
| Nim | [nim/i/interval_container.nim](../../../nim/i/interval_container.nim) |
| Odin | [odin/i/interval_container.odin](../../../odin/i/interval_container.odin) |
| Rust | [rust/i/interval_container.rs](../../../rust/i/interval_container.rs) |
| V | [v/i/interval_container.v](../../../v/i/interval_container.v) |
| Zig | [zig/i/interval_container.zig](../../../zig/i/interval_container.zig) |
