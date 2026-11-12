# Sort Points by Argument

Sort integer vectors by their exact polar argument, increasing through the
angle seam at the negative x-axis. The zero vector has argument zero and ties
with the positive x-axis. The comparator separates the lower half-plane,
angle-zero ray, and upper half-plane, then uses a signed cross product to order
directions. Equal directions are ordered by squared length and coordinates so
the benchmark output is deterministic. No floating-point angle is computed.

The local [`to_polar_angle_degrees`](../../t/to_polar_angle_degrees/README.md)
converts one vector to a floating-point degree value. This benchmark sorts a
set using an exact comparator, including near-parallel integer vectors and
collinear ties.

## Bounded contract

The `i64_array_bytes_output` entry point is
`sort_points_by_argument(input, length, output, capacity)`. Input is
`[N,x0,y0,...]`, with `1<=N<=64` and coordinates in `[-10^9,10^9]`. Output is
the sorted list of coordinate pairs, each coordinate encoded as a
little-endian signed 64-bit integer. Success returns `16*N` bytes. Malformed
input returns `-1`; valid input with null or undersized output returns `-2`.
Errors leave output unchanged. The maximum input is 129 words, maximum output
is 1024 bytes, and fixed workspace is 16384 bytes.

The primary oracle uses the same half-plane and cross-product ordering as the
ported algorithm. The independent oracle constructs exact rational-slope keys
within monotone angular sectors. Both use the same explicit distance and
coordinate tie-break to resolve equal arguments.

[`workload.json`](workload.json) records the bounds and fixtures.
[`verify_workload.py`](verify_workload.py) checks fixture/oracle agreement,
provenance, and all ten source paths; it has not been run.

## Provenance and rights

The contract and angle convention come from Library Checker's
[Sort Points by Argument task](https://github.com/yosupo06/library-checker-problems/blob/master/geo/sort_points_by_argument/task.md).
The problem repository is Apache-2.0. The local comparator, tie policy,
bounded interface, fixtures, oracles, documentation, and ports are clean-room
work; no upstream implementation or prose was copied. See [`RIGHTS.md`](RIGHTS.md).

## Implementations

| Language | Source |
|---|---|
| C | [`c/s/sort_points_by_argument.c`](../../../c/s/sort_points_by_argument.c) |
| C3 | [`c3/s/sort_points_by_argument.c3`](../../../c3/s/sort_points_by_argument.c3) |
| C++ | [`cpp/s/sort_points_by_argument.cpp`](../../../cpp/s/sort_points_by_argument.cpp) |
| Elisa | [`elisa/s/sort_points_by_argument.elisa`](../../../elisa/s/sort_points_by_argument.elisa) |
| Mojo | [`mojo/s/sort_points_by_argument.mojo`](../../../mojo/s/sort_points_by_argument.mojo) |
| Nim | [`nim/s/sort_points_by_argument.nim`](../../../nim/s/sort_points_by_argument.nim) |
| Odin | [`odin/s/sort_points_by_argument.odin`](../../../odin/s/sort_points_by_argument.odin) |
| Rust | [`rust/s/sort_points_by_argument.rs`](../../../rust/s/sort_points_by_argument.rs) |
| V | [`v/s/sort_points_by_argument.v`](../../../v/s/sort_points_by_argument.v) |
| Zig | [`zig/s/sort_points_by_argument.zig`](../../../zig/s/sort_points_by_argument.zig) |

Root owns shared suite registration and benchmark-corpus wiring.
