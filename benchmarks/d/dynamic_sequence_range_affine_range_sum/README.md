# Dynamic sequence range affine range sum

This bounded profile maintains a positional sequence under insertion, deletion,
half-open range reversal, modular affine range updates, and modular range-sum
queries. A deterministic implicit treap stores subtree sizes and modular sums;
lazy affine maps and reversal flags are pushed before structural changes.

## Contract

The flat input is `[N,Q,initial...,operations...]`. Operation tags follow the
Library Checker task: `0 i x` inserts `x` before position `i` (or appends at
`i == length`); `1 i` erases position `i`; `2 l r` reverses `[l,r)`; `3 l r b c`
maps every value in `[l,r)` to `(b*x+c) mod 998244353`; and `4 l r` appends
the modular sum of `[l,r)` to the output. Positions and ranges are validated
against the sequence length at the time each operation occurs.

Local bounds are `0<=N<=32`, `0<=Q<=32`, current length at most 64, and initial,
inserted, and affine coefficients in `[0,998244353)`. The valid input can use
at most 194 signed 64-bit words; 195 words are accepted by the parser bound so
trailing input can be rejected explicitly. Each query emits one little-endian
signed 64-bit residue, at most 256 bytes. Invalid input returns `-1`; null or
undersized output returns `-2` without writing output. The complete input is
validated before output-buffer checks.

The algorithm is distinct from the local fixed-array affine segment tree and
the reversal-only implicit treap: insertions and deletions shift positional
indices dynamically while all three lazy sequence operations remain available.
The primary oracle mutates a plain Python list; the independent oracle uses
slice reconstruction for reversals and updates.

## Source and rights

The operation semantics and published limits come from [Library Checker:
Dynamic Sequence Range Affine Range Sum](https://github.com/yosupo06/library-checker-problems/blob/master/data_structure/dynamic_sequence_range_affine_range_sum/task.md)
and its [limits](https://raw.githubusercontent.com/yosupo06/library-checker-problems/master/data_structure/dynamic_sequence_range_affine_range_sum/info.toml).
Only the problem contract and limits are used; implementations and local
fixtures are independently authored. See [`RIGHTS.md`](RIGHTS.md).

## Ports

| Language | Source |
|---|---|
| C | [`c/d/dynamic_sequence_range_affine_range_sum.c`](../../../c/d/dynamic_sequence_range_affine_range_sum.c) |
| C3 | [`c3/d/dynamic_sequence_range_affine_range_sum.c3`](../../../c3/d/dynamic_sequence_range_affine_range_sum.c3) |
| C++ | [`cpp/d/dynamic_sequence_range_affine_range_sum.cpp`](../../../cpp/d/dynamic_sequence_range_affine_range_sum.cpp) |
| Elisa | [`elisa/d/dynamic_sequence_range_affine_range_sum.elisa`](../../../elisa/d/dynamic_sequence_range_affine_range_sum.elisa) |
| Mojo | [`mojo/d/dynamic_sequence_range_affine_range_sum.mojo`](../../../mojo/d/dynamic_sequence_range_affine_range_sum.mojo) |
| Nim | [`nim/d/dynamic_sequence_range_affine_range_sum.nim`](../../../nim/d/dynamic_sequence_range_affine_range_sum.nim) |
| Odin | [`odin/d/dynamic_sequence_range_affine_range_sum.odin`](../../../odin/d/dynamic_sequence_range_affine_range_sum.odin) |
| Rust | [`rust/d/dynamic_sequence_range_affine_range_sum.rs`](../../../rust/d/dynamic_sequence_range_affine_range_sum.rs) |
| V | [`v/d/dynamic_sequence_range_affine_range_sum.v`](../../../v/d/dynamic_sequence_range_affine_range_sum.v) |
| Zig | [`zig/d/dynamic_sequence_range_affine_range_sum.zig`](../../../zig/d/dynamic_sequence_range_affine_range_sum.zig) |

See [`workload.json`](workload.json), [`oracle.py`](oracle.py),
[`independent_oracle.py`](independent_oracle.py), and [`verify_workload.py`](verify_workload.py).
Shared benchmark-suite registration is handled separately.
