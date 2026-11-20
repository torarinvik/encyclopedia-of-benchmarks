# Klarner–Rado affine-closure sequence (A005658)

Return the requested one-based term of the increasing, duplicate-free closure
of `{1}` under the three maps `x -> 2*x`, `x -> 3*x + 2`, and `x -> 6*x + 3`.
The input ABI is an i64 array `[k]`, with `1 <= k <= 64`; malformed framing or
an out-of-range index returns `-1`. The maximum supported result is 120.

This package is deliberately pinned to OEIS A005658. The similarly named
A002977 sequence starts at 1 and instead closes under `2*x + 1` and `3*x + 1`;
that is a different sequence and is not this contract. The primary merges
three increasing transformed streams with one cursor per map and advances
all tied cursors to deduplicate values. The independent reference uses a
min-heap and a set of discovered closure members. For k<=64, the largest
published term is 120 and the greatest transformed candidate needed to
produce it is 699. The primary stores 64 i64 terms (512 bytes); native ports
use no dynamic allocation. The documented 1,024-byte stack ceiling includes
the term table, scalar cursors, and alignment.

MathWorld gives the exact A005658 maps and initial terms in its
[Klarner–Rado sequence definition](https://mathworld.wolfram.com/Klarner-RadoSequence.html).
The affine-closure context is described in Klarner and Rado,
[“Arithmetic Properties of Certain Recursively Defined Sets”](https://doi.org/10.2140/pjm.1974.53.445),
and their earlier [“Linear Combinations of Sets of Consecutive Integers”](https://doi.org/10.1080/00029890.1973.11993430).
The [OEIS A005658 entry](https://oeis.org/A005658) independently states the
maps and supplies the prefix checkpoints. The pinned
[RosettaCodeData popular-title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used only to discover the task title; no task text, code, examples, or
tests were reused.

## Language ports

| Language | Source |
|---|---|
| C | [`c/k/klarner_rado_affine_closure_sequence.c`](../../../c/k/klarner_rado_affine_closure_sequence.c) |
| C++ | [`cpp/k/klarner_rado_affine_closure_sequence.cpp`](../../../cpp/k/klarner_rado_affine_closure_sequence.cpp) |
| Rust | [`rust/k/klarner_rado_affine_closure_sequence.rs`](../../../rust/k/klarner_rado_affine_closure_sequence.rs) |
| Elisa | [`elisa/k/klarner_rado_affine_closure_sequence.elisa`](../../../elisa/k/klarner_rado_affine_closure_sequence.elisa) |
| C3 | [`c3/k/klarner_rado_affine_closure_sequence.c3`](../../../c3/k/klarner_rado_affine_closure_sequence.c3) |
| Nim | [`nim/k/klarner_rado_affine_closure_sequence.nim`](../../../nim/k/klarner_rado_affine_closure_sequence.nim) |
| Odin | [`odin/k/klarner_rado_affine_closure_sequence.odin`](../../../odin/k/klarner_rado_affine_closure_sequence.odin) |
| V | [`v/k/klarner_rado_affine_closure_sequence.v`](../../../v/k/klarner_rado_affine_closure_sequence.v) |
| Zig | [`zig/k/klarner_rado_affine_closure_sequence.zig`](../../../zig/k/klarner_rado_affine_closure_sequence.zig) |
| Mojo | [`mojo/k/klarner_rado_affine_closure_sequence.mojo`](../../../mojo/k/klarner_rado_affine_closure_sequence.mojo) |

All implementations are clean-room translations of the mathematical
recurrence. No programs, tests, scripts, checkers, builds, compilers,
profilers, or benchmarks were run.
