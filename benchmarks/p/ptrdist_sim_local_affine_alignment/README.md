# Ptrdist SIM first-best local affine alignment

This bounded package isolates the first-best local similarity score from the
pinned Ptrdist SIM source. It follows `sim.c::big_pass` with the source default
integer scoring: a match contributes 10, any mismatch contributes -10, and a
gap of length `k` costs `60 + 2*k`. These values are the source's default
parameters multiplied by ten and rounded before dynamic programming. The
profile accepts uppercase DNA symbols `A`, `C`, `G`, and `T`.

## Contract

The `i64_array_scalar` input is
`[left_length, left_ascii..., right_length, right_ascii...]`. Each sequence has
length 1–64. The result is the maximum local affine-gap similarity score in
source integer tenths; a valid input with no positive-scoring alignment
returns 0. Malformed framing, out-of-range lengths, or symbols outside the
four-symbol DNA alphabet return `-1`.

The source launcher requests `K=8` alignments from the two supplied sequence
files. This profile reports only the first-best score from the initial full
matrix pass. It does not implement SIM's later iterative recomputation that
finds additional alignments with nonintersecting aligned pairs, nor file I/O,
alignment display, or the source's runtime output.

The independent oracle uses full three-matrix local dynamic programming. It
does not reproduce SIM's linear-space divide-and-conquer traceback.

## Provenance and rights

Pinned source: [`lac-dcc/Benchmarks` `sim/sim.c` at
`5d7b75df749241efa7a6e6f5be613d3fcc5cce38`](https://github.com/lac-dcc/Benchmarks/blob/5d7b75df749241efa7a6e6f5be613d3fcc5cce38/sim/sim.c).
The launcher is `sim/info.sh` and supplies `8 tob.38-44 liv.42-48`; the source
documents match, transition, transversion, gap-open, and gap-extension defaults
and identifies the first result as the highest-scoring local alignment. The
source is copyright 1990 Xiaoqiu Huang and Webb Miller and gives attribution
and paper references, but contains no explicit redistribution license grant.
All ports here are clean-room implementations of the documented recurrence;
no upstream source code or comments are copied. This notice does not claim an
upstream license or grant additional rights.

## Language ports

| Language | Source |
|---|---|
| C | [`c/p/ptrdist_sim_local_affine_alignment.c`](../../../c/p/ptrdist_sim_local_affine_alignment.c) |
| C3 | [`c3/p/ptrdist_sim_local_affine_alignment.c3`](../../../c3/p/ptrdist_sim_local_affine_alignment.c3) |
| C++ | [`cpp/p/ptrdist_sim_local_affine_alignment.cpp`](../../../cpp/p/ptrdist_sim_local_affine_alignment.cpp) |
| Elisa | [`elisa/p/ptrdist_sim_local_affine_alignment.elisa`](../../../elisa/p/ptrdist_sim_local_affine_alignment.elisa) |
| Nim | [`nim/p/ptrdist_sim_local_affine_alignment.nim`](../../../nim/p/ptrdist_sim_local_affine_alignment.nim) |
| Odin | [`odin/p/ptrdist_sim_local_affine_alignment.odin`](../../../odin/p/ptrdist_sim_local_affine_alignment.odin) |
| Rust | [`rust/p/ptrdist_sim_local_affine_alignment.rs`](../../../rust/p/ptrdist_sim_local_affine_alignment.rs) |
| V | [`v/p/ptrdist_sim_local_affine_alignment.v`](../../../v/p/ptrdist_sim_local_affine_alignment.v) |
| Zig | [`zig/p/ptrdist_sim_local_affine_alignment.zig`](../../../zig/p/ptrdist_sim_local_affine_alignment.zig) |

Independent oracle: [`ptrdist_sim_local_affine_alignment_oracle.py`](../../ptrdist_sim_local_affine_alignment_oracle.py).
