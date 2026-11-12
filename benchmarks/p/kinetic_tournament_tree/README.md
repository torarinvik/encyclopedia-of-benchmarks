# Kinetic tournament tree

Maintain a small ordered set of linear functions `f_i(x)=slope_i*x+intercept_i`.
A range translation by positive integer `delta` replaces each function in the
range with `f_i(x+delta)`, which adds `slope_i*delta` to its intercept. A range
maximum query returns the largest current value at `x=0`.

The benchmark uses a kinetic tournament tree over a fixed segment-tree layout.
Each node stores its current winning line, a uniform translation tag, and the
earliest certificate deadline in its subtree. A winner with a smaller slope
than its competitor has a future crossing; the certificate deadline is the
ceiling of the intercept gap divided by the slope gap. A range translation
subtracts its delta from affected deadlines. Expired certificates trigger
repair down the tree, after which winners and deadlines are recomputed. Slopes
are strictly increasing, and equal current values choose the line with larger
slope.

This differs from [`li_chao_tree`](../../l/li_chao_tree/README.md), which
inserts a static set of lines and queries supplied coordinates. The kinetic
tournament tree tracks changing winners as range translations advance
certificate times.

## Bounded contract

The `i64_array_bytes_output` entry point is
`kinetic_tournament_tree(input, length, output, capacity)`. Input is
`[N,M,(slope,intercept)*N, then M tagged operations]`, with `1<=N<=8` and
`1<=M<=32`. Slopes are distinct integers in `[-8,8]` and must be strictly
increasing; initial intercepts are in `[-64,64]`. A translation is
`[0,left,right,delta]` and requires `1<=delta<=8`; a query is
`[1,left,right]`. Ranges use inclusive, zero-based indices. At least one query
is required.

Output is one little-endian signed 64-bit maximum per query, in operation
order. Success returns `8*query_count` bytes. Malformed input returns `-1`; a
null or undersized output returns `-2`; errors leave the output unchanged.
The maximum valid input length is 145 words; 146 words is the parser's maximum
length so it can reject a trailing-word malformed frame. Maximum output is 256
bytes, and fixed workspace is 8192 bytes. Coefficient and update bounds keep all intermediate
values safely within signed 64-bit range.

The primary oracle maintains certificate deadlines and repairs them in a
segment-tree tournament. The independent oracle applies each update to every
line in its range and evaluates every line directly for each query. The
bounded update profile follows the kinetic structure's amortized
`O(log^3 N)` update behavior; direct queries take `O(N)`.

[`workload.json`](workload.json) records the contract and fixtures.
[`verify_workload.py`](verify_workload.py) checks fixture/oracle agreement,
provenance, and the ten source paths; it is included for later review and has
not been run.

## Provenance and rights

The algorithm was discovered in OI Wiki's
[Kinetic Tournament Tree article](https://oi-wiki.org/ds/kinetic-tournament-tree/),
which lists CC BY-SA 4.0 and SATA terms. The package uses the algorithm
description for discovery and attribution. Its bounded interface, fixtures,
oracles, prose, and implementations are clean-room work; no upstream source
code or article prose was copied. See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/p/kinetic_tournament_tree.c`](../../../c/p/kinetic_tournament_tree.c) |
| C3 | [`c3/p/kinetic_tournament_tree.c3`](../../../c3/p/kinetic_tournament_tree.c3) |
| C++ | [`cpp/p/kinetic_tournament_tree.cpp`](../../../cpp/p/kinetic_tournament_tree.cpp) |
| Elisa | [`elisa/p/kinetic_tournament_tree.elisa`](../../../elisa/p/kinetic_tournament_tree.elisa) |
| Mojo | [`mojo/p/kinetic_tournament_tree.mojo`](../../../mojo/p/kinetic_tournament_tree.mojo) |
| Nim | [`nim/p/kinetic_tournament_tree.nim`](../../../nim/p/kinetic_tournament_tree.nim) |
| Odin | [`odin/p/kinetic_tournament_tree.odin`](../../../odin/p/kinetic_tournament_tree.odin) |
| Rust | [`rust/p/kinetic_tournament_tree.rs`](../../../rust/p/kinetic_tournament_tree.rs) |
| V | [`v/p/kinetic_tournament_tree.v`](../../../v/p/kinetic_tournament_tree.v) |
| Zig | [`zig/p/kinetic_tournament_tree.zig`](../../../zig/p/kinetic_tournament_tree.zig) |

The shared byte-output suite registers the certificate-tree oracle, direct
evaluator, bounds, maximum-query and longest-valid-frame profiles, malformed
input cases, and output-capacity cases. The package checker and suite have not
been run.
