# Position-only Störmer–Verlet integration

This benchmark applies the two-position Verlet recurrence to a one-dimensional
trajectory with a supplied acceleration-displacement term at each step. It
stores no velocity state. The existing [`verlet`](../../v/verlet/README.md)
profile is velocity-Verlet with position and velocity state, so these exercise
different update equations and state representations.

## Contract

- ABI: `i64_array_bytes_output`; exported symbol:
  `stormer_verlet_position`.
- Input is `[N, x0, x1, u0, ..., u(N-3)]`, exactly `N+1` signed-i64 values.
  `N` is 2–32; each initial position is in `[-1024,1024]`; each update term
  `u[k]` is in `[-64,64]`.
- `x0` and `x1` are the first two sampled positions. For `i=2..N-1`, compute
  `x[i] = 2*x[i-1] - x[i-2] + u[i-2]`. The input term `u[k]` represents the
  physical acceleration contribution `a[k]*dt²`; this precombined integer
  representation keeps the recurrence exact and avoids floating-point
  differences across languages.
- Output is all `N` positions as little-endian signed-i64 values, including
  the two initial positions. Success returns `8*N` bytes. Invalid framing or
  values return `-1`; a null or undersized output buffer returns `-2`. All
  validation precedes output writes, and errors leave output unchanged.
- The valid input is at most 33 words. For `N<=32`, the recurrence remains
  within signed-i64 bounds; the local staged output is at most 256 bytes.

The recurrence takes O(N) time. The implementation uses two position scalars
and a 256-byte output staging buffer, with no heap allocation. The independent
reference uses the closed-form finite-difference sum in O(N²), rather than the
two-state recurrence.

## Sources and clean-room status

The [Algorithm Archive Verlet Integration chapter](https://www.algorithm-archive.org/contents/verlet_integration/verlet_integration.html)
derives the position-only update from forward and backward Taylor expansions,
then presents velocity-Verlet separately. The [PARSEC Facesim metadata](https://github.com/cirosantilli/parsec-benchmark/blob/master/pkgs/apps/facesim/src/README)
is a second discovery source: it identifies Verlet updates for positions in a
physical-simulation application, but does not specify the recurrence used by
this bounded profile. The mathematical update here follows the Algorithm
Archive description; the input representation, integer contract, code,
references, and fixtures were independently authored. No upstream code or
prose was copied. See [`RIGHTS.md`](RIGHTS.md).

## Workload and references

- Workload: [`workload.json`](workload.json)
- Primary recurrence reference: [`stormer_verlet_position_oracle.py`](../../stormer_verlet_position_oracle.py)
- Independent closed-form reference: [`independent_oracle.py`](independent_oracle.py)
- Static inventory: [`INVENTORY.md`](INVENTORY.md)
- Static workload verifier: [`verify_workload.py`](verify_workload.py)

The ten language ports are registered with the `i64_array_bytes_output`
runner and verifier, and the profile appears in the catalog and PARSEC/Archive
source crosswalk. No port or package checker has been run.
- Static inventory verifier: [`check_inventory.py`](check_inventory.py)

## Language ports

| Language | Source |
|---|---|
| C | [stormer_verlet_position.c](../../../c/s/stormer_verlet_position.c) |
| C3 | [stormer_verlet_position.c3](../../../c3/s/stormer_verlet_position.c3) |
| C++ | [stormer_verlet_position.cpp](../../../cpp/s/stormer_verlet_position.cpp) |
| Elisa | [stormer_verlet_position.elisa](../../../elisa/s/stormer_verlet_position.elisa) |
| Mojo | [stormer_verlet_position.mojo](../../../mojo/s/stormer_verlet_position.mojo) |
| Nim | [stormer_verlet_position.nim](../../../nim/s/stormer_verlet_position.nim) |
| Odin | [stormer_verlet_position.odin](../../../odin/s/stormer_verlet_position.odin) |
| Rust | [stormer_verlet_position.rs](../../../rust/s/stormer_verlet_position.rs) |
| V | [stormer_verlet_position.v](../../../v/s/stormer_verlet_position.v) |
| Zig | [stormer_verlet_position.zig](../../../zig/s/stormer_verlet_position.zig) |
