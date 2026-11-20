# Arbitrary-axis finite vector rotation

This package rotates one 3D vector about a caller-supplied nonzero axis. This differs from `vector3_axis_rotation`, which selects only a coordinate axis and applies its pinned angle conversion, and from fixed-point CORDIC, which traces planar shift-add stages. The method here is the vector form of the finite-rotation identity

```text
r' = r cos(theta) + (n x r) sin(theta) + n (n dot r) (1 - cos(theta))
```

where `n` is the normalized axis and `theta` is in radians. The axis is normalized with max-component scaling to handle both large and subnormal nonzero scales without squaring an unscaled value. This is a single-vector action; the profile does not convert rotation parameters or compose rotations.

## Contract

The `float64_slice_io` input is `[axis_x,axis_y,axis_z,vector_x,vector_y,vector_z,angle_radians]`. It must contain exactly seven finite values. Axis and vector components have absolute value at most 1,000,000; the axis must be nonzero and the angle must lie in `[-2*pi,2*pi]`. The output is `[rotated_x,rotated_y,rotated_z]`, with three finite values bounded by 2,000,000.

The operation order is pinned in [`workload.json`](workload.json): scale and normalize the axis, compute cosine/sine and `1-cosine`, form `n x r` and `n dot r`, then evaluate each output component as `(v_i*c + cross_i*s) + (n_i*dot)*d`. Implementations should not assume fast-math reassociation. Malformed input returns `-1`. After validating and computing the result, a null output or capacity below three returns `-2`; errors write nothing. Success returns `3`. Tolerance is `1e-9` absolute and `2e-12` relative, allowing small absolute residuals across math libraries and the two arithmetic forms at vector magnitudes up to one million.

The primary reference evaluates the vector identity directly. The independent reference constructs the 3x3 matrix `I + [n]x sin(theta) + [n]x^2(1-cos(theta))` and applies it to the vector. The bounded kernel takes O(1) time and auxiliary space; workspace is conservatively capped at 256 bytes, including the staged three-element result.

## Source and naming

The cited 1989 historical paper gives the vector finite-rotation formula as Euler's finite rotation formula and distinguishes it from Rodrigues' composition formulas and parameters. The common name “Rodrigues rotation formula” is retained in the package identifier because it is the title-index lead and the name used by modern references. The mathematical formula appears as Eq. 1 in Hui Cheng and K. C. Gupta, “An Historical Note on Finite Rotations,” *Journal of Applied Mechanics* 56 (1989), 139–142, [paper](https://iel.ucdavis.edu/publication/1989/j_ASMEAM.pdf). For the matrix representation, see Eric Weisstein, [“Rodrigues' Rotation Formula,” MathWorld](https://mathworld.wolfram.com/RodriguesRotationFormula.html).

The package was written clean-room from the mathematical formula. No source code, task statements, examples, or tests were copied. See [`RIGHTS.md`](RIGHTS.md) for provenance details.

## Language ports

| Language | Source |
|---|---|
| C | [`c/r/rodrigues_arbitrary_axis_rotation.c`](../../../c/r/rodrigues_arbitrary_axis_rotation.c) |
| C3 | [`c3/r/rodrigues_arbitrary_axis_rotation.c3`](../../../c3/r/rodrigues_arbitrary_axis_rotation.c3) |
| C++ | [`cpp/r/rodrigues_arbitrary_axis_rotation.cpp`](../../../cpp/r/rodrigues_arbitrary_axis_rotation.cpp) |
| Elisa | [`elisa/r/rodrigues_arbitrary_axis_rotation.elisa`](../../../elisa/r/rodrigues_arbitrary_axis_rotation.elisa) |
| Mojo | [`mojo/r/rodrigues_arbitrary_axis_rotation.mojo`](../../../mojo/r/rodrigues_arbitrary_axis_rotation.mojo) |
| Nim | [`nim/r/rodrigues_arbitrary_axis_rotation.nim`](../../../nim/r/rodrigues_arbitrary_axis_rotation.nim) |
| Odin | [`odin/r/rodrigues_arbitrary_axis_rotation.odin`](../../../odin/r/rodrigues_arbitrary_axis_rotation.odin) |
| Rust | [`rust/r/rodrigues_arbitrary_axis_rotation.rs`](../../../rust/r/rodrigues_arbitrary_axis_rotation.rs) |
| V | [`v/r/rodrigues_arbitrary_axis_rotation.v`](../../../v/r/rodrigues_arbitrary_axis_rotation.v) |
| Zig | [`zig/r/rodrigues_arbitrary_axis_rotation.zig`](../../../zig/r/rodrigues_arbitrary_axis_rotation.zig) |

The ten ports, both references, fixtures and package inventory have only been statically reviewed; no programs or checks were run.
