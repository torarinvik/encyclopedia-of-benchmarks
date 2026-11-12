# SPLASH-2 FMM: bounded uniform 2-D profile

This package implements a clean-room, fixed-grid, single-level fast multipole
method (FMM) for the two-dimensional Laplace logarithmic potential. It is an
algorithmic projection inspired by SPLASH-2 FMM, not a source translation or a
reproduction of its adaptive tree, parallel runtime, timestep integration, or
launcher-scale particle workload.

## Algorithm

The SPLASH-2 characterization paper describes FMM as a two-dimensional
adaptive N-body algorithm. Its tree is processed through upward and downward
passes, unlike Barnes–Hut's per-body traversal; its accuracy is controlled by
the accuracy of each cell interaction rather than the count of accepted
interactions. The repository's [`olden_bh`](../../o/olden_bh/README.md) is a
three-dimensional octree using a monopole and a geometric opening rule. This
package captures a different method: fixed-order complex multipole and local
expansions, a multipole-to-local translation for well-separated boxes, and
direct evaluation for the near field.

Particles occupy a fixed 4 by 4 grid of square boxes with side length 2. For a
source box centered at `c`, the upward particle-to-multipole step computes
`Q = sum(q)` and `M_k = sum(q * (z-c)^k)` for orders 1 through 32. For each
target box, every non-neighbor source box is translated into a local expansion
through order 32. The downward evaluation adds the local expansion at each
target and directly sums sources in the target's own and adjacent boxes. The
far-field criterion is a Chebyshev box distance greater than one. This is a
single-level FMM: no parent-child M2M or L2L shifts are needed because the
contract has one box level.

Input is `[particle_count, (x,y,charge)*]`. There are 2–48 particles, integer
coordinates in `[0,8)` on each axis, integer charges in `[-3,3]`, and no
coincident positions. Each output is
`sum(j != i, charge_j * ln(distance(i,j)))` in particle input order. Invalid
input returns `-1`; a null or short output buffer returns `-2` without writes.
The workload tolerance is `1e-10` absolute and relative. The independent
all-pairs oracle and the target-wise verifier use direct logarithmic
interactions, not multipole expansions.

The uniform grid is bounded and the direct near field can be quadratic in a
crowded input. The measured work still includes the FMM-specific P2M and M2L
expansion machinery, rather than Barnes–Hut's monopole acceptance traversal.
See [`workload.json`](workload.json), [`splash2_fmm_oracle.py`](../../splash2_fmm_oracle.py),
[`splash2_fmm_verifier_oracle.py`](../../splash2_fmm_verifier_oracle.py), and
[`RIGHTS.md`](RIGHTS.md).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/f/splash2_fmm.c`](../../../c/f/splash2_fmm.c) |
| C3 | [`c3/f/splash2_fmm.c3`](../../../c3/f/splash2_fmm.c3) |
| C++ | [`cpp/f/splash2_fmm.cpp`](../../../cpp/f/splash2_fmm.cpp) |
| Elisa | [`elisa/f/splash2_fmm.elisa`](../../../elisa/f/splash2_fmm.elisa) |
| Mojo | [`mojo/f/splash2_fmm.mojo`](../../../mojo/f/splash2_fmm.mojo) |
| Nim | [`nim/f/splash2_fmm.nim`](../../../nim/f/splash2_fmm.nim) |
| Odin | [`odin/f/splash2_fmm.odin`](../../../odin/f/splash2_fmm.odin) |
| Rust | [`rust/f/splash2_fmm.rs`](../../../rust/f/splash2_fmm.rs) |
| V | [`v/f/splash2_fmm.v`](../../../v/f/splash2_fmm.v) |
| Zig | [`zig/f/splash2_fmm.zig`](../../../zig/f/splash2_fmm.zig) |

No program, test, build, compiler, benchmark, script, or checker was executed
while authoring this package.
