# Smallest enclosing ball in 3D

This benchmark computes the minimum-radius sphere enclosing a bounded 3D
point set using Welzl's incremental support-set algorithm with a support set of
at most four points. The source implementation permutes the input and
recursively removes the final point, adding it to the support set when the
current sphere does not contain it. This profile uses a deterministic
lexicographic point order so repeated calls have stable floating-point output.

## Contract

The `float64_slice_io` symbol is `smallest_enclosing_ball_3d`. Input is
`[n,x0,y0,z0,...]`, with `1 <= n <= 8`, exactly `1 + 3*n` finite binary64
values, and coordinates in `[-10,10]`. Duplicate points are accepted. The
output is four binary64 values `(center_x,center_y,center_z,radius)`. Invalid
input returns `-1`; null output or capacity below four values returns `-2`
without writing. The independent oracle enumerates all candidate support sets
of size at most four, rather than using Welzl recursion.

## Pinned source and license

Based on Anton Semechko, `ExactMinBoundSphere3D.m` and
`Auxiliary/FitMinSphere2Points.m`, pinned at
[`a6e9fe28d5239fdf72055a5ff7116bb08b2135de`](https://github.com/antonsemechko/bounding-spheres-and-circles/tree/a6e9fe28d5239fdf72055a5ff7116bb08b2135de).
The exact source uses Welzl recursion and a support set of at most four points;
its fit routine handles one-point, pair, triangle, and tetrahedron supports.
The repository is MIT licensed. Its complete notice is bundled in
[`LICENSE.txt`](LICENSE.txt).

## Ports

The nine ports are under `c/s`, `c3/s`, `cpp/s`, `elisa/s`, `nim/s`, `odin/s`,
`rust/s`, `v/s`, and `zig/s`.
