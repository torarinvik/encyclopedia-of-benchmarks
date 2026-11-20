# Kirkpatrick–Seidel convex hull

This package implements Kirkpatrick and Seidel's marriage-before-conquest
planar convex-hull method. It recursively splits at a median x-coordinate,
finds an upper bridge spanning that separator, removes points strictly below
the bridge, and continues on the point sets to its left and right. The lower
chain is computed by reflecting y-coordinates and applying the same upper
chain kernel. Each bridge uses median-of-medians selection for pair slopes;
exact cross-products compare rational slopes without division. The hull
kernel is `O(n log h)` time and `O(n)` workspace for `h` output vertices.

## Contract

- ABI: `i64_array_bytes_output`; symbol:
  `kirkpatrick_seidel_convex_hull`.
- Input is `[n,x0,y0,...]`, with `3 <= n <= 32` and integer coordinates in
  `[-1000,1000]`.
- Every x-coordinate must be unique. The point set must contain a
  non-collinear triple. Collinear boundary points are accepted and omitted
  from the strict hull. Duplicate x-coordinates, including duplicate points,
  are invalid.
- Output contains the strict convex-hull vertices in counterclockwise order,
  beginning at the lexicographically least point, as little-endian signed-i64
  coordinate pairs. The returned value is the byte count. At most 512 bytes
  are written.
- Invalid input returns `-1`. Valid input with null or short output returns
  `-2`. Errors write nothing. Maximum valid and parseable input lengths are
  65 and 66 words.
- Workspace is bounded to 16,384 bytes, excluding caller-owned input and
  output. Coordinates keep orientation, slope-comparison, and support-line
  products safely within signed 64-bit arithmetic.

## Pinned method rules

Candidate lists retain original input order through filtering. Each bridge
iteration pairs consecutive candidates in that order; each pair is oriented
left-to-right only for its slope. Both separator x and pair slope use the
lower median, selected deterministically by groups-of-five
median-of-medians. The support line maximizes `y*dxK - dyK*x`; its contacts
are the minimum-x and maximum-x maximizers. A bridge crosses when
`x(left) <= separator < x(right)`, so a separator on a hull vertex selects
the edge leaving it to the right.

If the support contacts lie on or left of the separator, pairs with slope
below the median retain both endpoints and pairs at or above it retain the
right endpoint. If the contacts lie right of the separator, pairs above the
median retain both endpoints and pairs at or below it retain the left
endpoint. An unpaired candidate is retained. This treats equal slopes as a
whole group and preserves the paper's constant-fraction pruning. Points
collinear with a support line are represented by their extreme-x contacts,
which omits intermediate boundary points from the output.

The primary reference implements the recursive bridge method with exact
selection. The independent `O(n^3)` reference enumerates supporting point
pairs, collapses each support line to its extreme contacts, orients directed
boundary edges, and follows the resulting cycle. It shares neither bridge
selection nor recursive pruning.

The method is distinct from local
[`chan_output_sensitive_hull`](../../c/chan_output_sensitive_hull/README.md), which
builds group hulls and wraps with tangent searches and retries, and
[`divide_conquer_tangent_hull`](../../d/divide_conquer_tangent_hull/README.md),
which constructs child hulls before merging them by tangent walks. K–S finds
bridges first and prunes the point set before recursing.

Primary source: Kirkpatrick and Seidel, “The Ultimate Planar Convex Hull
Algorithm?”, *SIAM Journal on Computing* 15(1), 1986,
[DOI 10.1137/0215021](https://doi.org/10.1137/0215021). The pinned
[RosettaCodeData popular-title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used for title discovery only. No task text, submitted code, examples,
tests, or fixtures were copied. See [RIGHTS.md](RIGHTS.md).

## Language ports

| Language | Source |
|---|---|
| C | [c/k/kirkpatrick_seidel_convex_hull.c](../../../c/k/kirkpatrick_seidel_convex_hull.c) |
| C3 | [c3/k/kirkpatrick_seidel_convex_hull.c3](../../../c3/k/kirkpatrick_seidel_convex_hull.c3) |
| C++ | [cpp/k/kirkpatrick_seidel_convex_hull.cpp](../../../cpp/k/kirkpatrick_seidel_convex_hull.cpp) |
| Elisa | [elisa/k/kirkpatrick_seidel_convex_hull.elisa](../../../elisa/k/kirkpatrick_seidel_convex_hull.elisa) |
| Mojo | [mojo/k/kirkpatrick_seidel_convex_hull.mojo](../../../mojo/k/kirkpatrick_seidel_convex_hull.mojo) |
| Nim | [nim/k/kirkpatrick_seidel_convex_hull.nim](../../../nim/k/kirkpatrick_seidel_convex_hull.nim) |
| Odin | [odin/k/kirkpatrick_seidel_convex_hull.odin](../../../odin/k/kirkpatrick_seidel_convex_hull.odin) |
| Rust | [rust/k/kirkpatrick_seidel_convex_hull.rs](../../../rust/k/kirkpatrick_seidel_convex_hull.rs) |
| V | [v/k/kirkpatrick_seidel_convex_hull.v](../../../v/k/kirkpatrick_seidel_convex_hull.v) |
| Zig | [zig/k/kirkpatrick_seidel_convex_hull.zig](../../../zig/k/kirkpatrick_seidel_convex_hull.zig) |

The [hand-authored workload](workload.json) covers canonical order, separator
ties, interior points, collinear boundary contacts, malformed input, and
output-capacity failures. References, ports, and inventory are source-only;
no programs, scripts, tests, checkers, builds, compilers, profilers, or
benchmarks have been run.
