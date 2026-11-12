# Range reverse range sum

This bounded profile maintains a sequence under half-open range reversal and
range-sum queries. It uses an implicit treap: subtree size gives each node's
sequence position, subtree sum answers covered ranges, and a lazy reversal flag
swaps children when pushed. Deterministic Park–Miller priorities derived by
advancing the fixed 48271 generator from original node IDs make the profile
reproducible; an ID tie-break makes the priority order total. This bounded
implementation profile does not claim a particular contest generator.

## Contract

The input is `[N,Q,a_0,...,a_(N-1),(type,left,right)*Q]`. `0 left right`
reverses `[left,right)`, and `1 left right` appends the sum of that interval.
The task permits empty intervals and an empty initial sequence. The local
bounds are `0<=N<=64`, `0<=Q<=32`, `0<=a_i<=1,000,000,000`, and
`0<=left<=right<=N`. Each answer is one little-endian signed 64-bit integer;
the largest output is 256 bytes. Invalid input returns `-1`; null output or
insufficient capacity returns `-2`, with no writes on error. Parsing of the
complete frame and all ranges precedes output checks. The maximum valid input
is 162 words; one extra parseable word is allowed to detect trailing input.

The implicit treap is algorithmically distinct from the local key-ordered
`splay_tree` and `treap_unique_key_set`: it supports positional split/merge,
lazy reversal, and sequence aggregates rather than ordered-set operations.
The primary oracle applies swaps to a plain list; the independent checker uses
immutable slice reversal.

## Source and rights

The contract follows [Library Checker: Range Reverse Range Sum](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_reverse_range_sum/task.md)
and its [limits](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/range_reverse_range_sum/info.toml).
The repository is Apache-2.0. Only task semantics and constraints are used;
the ports and fixtures are independently written. See [RIGHTS.md](RIGHTS.md).

## Ports

| Language | Source |
|---|---|
| C | [`c/r/range_reverse_range_sum.c`](../../../c/r/range_reverse_range_sum.c) |
| C3 | [`c3/r/range_reverse_range_sum.c3`](../../../c3/r/range_reverse_range_sum.c3) |
| C++ | [`cpp/r/range_reverse_range_sum.cpp`](../../../cpp/r/range_reverse_range_sum.cpp) |
| Elisa | [`elisa/r/range_reverse_range_sum.elisa`](../../../elisa/r/range_reverse_range_sum.elisa) |
| Mojo | [`mojo/r/range_reverse_range_sum.mojo`](../../../mojo/r/range_reverse_range_sum.mojo) |
| Nim | [`nim/r/range_reverse_range_sum.nim`](../../../nim/r/range_reverse_range_sum.nim) |
| Odin | [`odin/r/range_reverse_range_sum.odin`](../../../odin/r/range_reverse_range_sum.odin) |
| Rust | [`rust/r/range_reverse_range_sum.rs`](../../../rust/r/range_reverse_range_sum.rs) |
| V | [`v/r/range_reverse_range_sum.v`](../../../v/r/range_reverse_range_sum.v) |
| Zig | [`zig/r/range_reverse_range_sum.zig`](../../../zig/r/range_reverse_range_sum.zig) |

See [`workload.json`](workload.json), [`range_reverse_range_sum_oracle.py`](../../range_reverse_range_sum_oracle.py),
[`range_reverse_range_sum_verifier_oracle.py`](../../range_reverse_range_sum_verifier_oracle.py),
and the package-local [`verify_workload.py`](verify_workload.py). No suite
registration is included in this package change.
