# SPLASH-2 Radiosity: bounded link refinement

This package implements a clean-room, bounded profile of hierarchical radiosity's patch-pair refinement operation. It processes one facing pair of square patches, refines the larger patch into four children when a coarse centroid interaction differs from the next quadrant estimate by more than a caller-provided probe threshold, and gathers the accepted links into one target value. It does not render a scene or reproduce the full SPLASH-2 Radiosity application.

## Contract

The `float64_slice_io` input contains eleven values: target center `(x,y)` and side length; source center `(x,y)` and side length; plane gap; source brightness; target reflectance; refinement-probe threshold; and maximum refinement depth. Each patch is an axis-aligned square on a parallel plane. The target faces the source. Side lengths are in `{1,2,4}`, the gap is in `[1,8]`, and neither side may exceed the gap. Coordinates are in `[-8,8]`, brightness in `[0,4]`, reflectance and probe threshold in `[0,1]`, and depth in `[0,5]`.

The centroid link estimate is `source_area * gap^2 / distance_squared^2`. It equals π times the centroid-sampled diffuse form factor. The kernel compares the current estimate with the next four-quadrant estimate. When the difference exceeds the threshold and depth remains, it splits the larger patch into four equal squares; ties split the source. Target-side descendants are gathered with one-quarter area weights. This coarse-versus-fine difference is a heuristic probe, not a certified bound on the exact patch integral. The three output values are scaled gathered radiosity, accepted leaf-link count, and deepest accepted link level. Invalid input returns `-1`; a null or short output buffer returns `-2` without writes.

This is a single patch-pair algorithmic projection. It excludes polygon visibility, scene setup, iterative convergence, display, task queues, stealing, and processor scheduling. The local package inventory contains quadtrees and other tree traversals, but no hierarchical radiosity form-factor or interaction-link refinement kernel.

## Oracles and workload

The primary recursive oracle is [`../../splash2_radiosity_oracle.py`](../../splash2_radiosity_oracle.py). The independent verifier uses a weighted explicit work stack in [`../../splash2_radiosity_verifier_oracle.py`](../../splash2_radiosity_verifier_oracle.py). [`workload.json`](workload.json) covers a coarse accepted link, source and target refinement, a zero-depth boundary, invalid framing/domain values, and output-buffer errors. [`verify_workload.py`](verify_workload.py) statically checks the contract, fixtures, provenance, and port paths.

## Provenance and rights

The [SPLASH-2 Radiosity source](https://github.com/staceyson/splash2/blob/master/codes/apps/radiosity/rad_main.C) carries Stanford University 1994 terms that allow use, copying, and modification for non-commercial purposes while forbidding redistribution of the original software, in whole or part, without prior written permission. This package does not copy, adapt, or redistribute that source. It also does not copy source comments, implementation text, or problem text. The implementation is written independently from the published algorithm description in Hanrahan, Salzman, and Aupperle's [“A Rapid Hierarchical Radiosity Algorithm”](https://doi.org/10.1145/122718.122740) and the high-level application summary in the [SPLASH-2 characterization paper](https://pages.cs.wisc.edu/~markhill/restricted/isca95_splash2.pdf). See [`RIGHTS.md`](RIGHTS.md) for the audit note.

## Language ports

| Language | Port |
|---|---|
| C | [`c/f/splash2_radiosity_refine.c`](../../../c/f/splash2_radiosity_refine.c) |
| C3 | [`c3/f/splash2_radiosity_refine.c3`](../../../c3/f/splash2_radiosity_refine.c3) |
| C++ | [`cpp/f/splash2_radiosity_refine.cpp`](../../../cpp/f/splash2_radiosity_refine.cpp) |
| Elisa | [`elisa/f/splash2_radiosity_refine.elisa`](../../../elisa/f/splash2_radiosity_refine.elisa) |
| Mojo | [`mojo/f/splash2_radiosity_refine.mojo`](../../../mojo/f/splash2_radiosity_refine.mojo) |
| Nim | [`nim/f/splash2_radiosity_refine.nim`](../../../nim/f/splash2_radiosity_refine.nim) |
| Odin | [`odin/f/splash2_radiosity_refine.odin`](../../../odin/f/splash2_radiosity_refine.odin) |
| Rust | [`rust/f/splash2_radiosity_refine.rs`](../../../rust/f/splash2_radiosity_refine.rs) |
| V | [`v/f/splash2_radiosity_refine.v`](../../../v/f/splash2_radiosity_refine.v) |
| Zig | [`zig/f/splash2_radiosity_refine.zig`](../../../zig/f/splash2_radiosity_refine.zig) |

No program, test, build, compiler, benchmark, script, or checker was executed while authoring this package.
