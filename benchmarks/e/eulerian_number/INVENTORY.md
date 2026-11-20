# Static inventory

- Contract, method distinction, and source notes: `README.md`.
- Provenance and rights scope: `RIGHTS.md`.
- Reservation and bounded contract: `RESERVATION.md`.
- Fixed workload cases: `workload.json`.
- Eulerian-row recurrence reference: `primary_oracle.py`.
- Inclusion-exclusion reference with arbitrary-precision arithmetic: `independent_oracle.py`.
- Package-local static fixture checks: `verify_workload.py`.
- Package artifact and source-presence checker: `check_inventory.py`.

All ten language ports export `eulerian_number`:

- [C](../../../c/e/eulerian_number.c)
- [C3](../../../c3/e/eulerian_number.c3)
- [C++](../../../cpp/e/eulerian_number.cpp)
- [Elisa](../../../elisa/e/eulerian_number.elisa)
- [Mojo](../../../mojo/e/eulerian_number.mojo)
- [Nim](../../../nim/e/eulerian_number.nim)
- [Odin](../../../odin/e/eulerian_number.odin)
- [Rust](../../../rust/e/eulerian_number.rs)
- [V](../../../v/e/eulerian_number.v)
- [Zig](../../../zig/e/eulerian_number.zig)

The `i64_array_scalar` runner and verifier and root catalog include this
package. No programs, checkers, tests, builds, compilers, or benchmarks were
run.
