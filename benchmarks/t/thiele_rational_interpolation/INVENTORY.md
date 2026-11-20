# Static inventory

This file is a human-readable list of package artifacts. `check_inventory.py` checks only file existence, source symbols, path mentions, and provenance URLs; it does not compile or execute a language port.

| Artifact | Role |
| --- | --- |
| `workload.json` | Bounded input/output contract, timing profiles, expected fixtures, and ABI boundary fixtures |
| `primary_oracle.py` | Binary64 inverse-difference table and nested continued-fraction evaluator |
| `independent_oracle.py` | Exact `Fraction` homogeneous linear-system solution for the prescribed rational degree pair, with guarded binary64 fallback when exact rank/pole checks cannot produce a unique value |
| `verify_workload.py` | Static fixture comparison against both references |
| `check_inventory.py` | Static source and provenance inventory |
| `c/t/thiele_rational_interpolation.c` | C ABI port |
| `c3/t/thiele_rational_interpolation.c3` | C3 ABI port |
| `cpp/t/thiele_rational_interpolation.cpp` | C++ ABI port |
| `elisa/t/thiele_rational_interpolation.elisa` | Elisa ABI port with typed views inside the implementation |
| `mojo/t/thiele_rational_interpolation.mojo` | Mojo ABI port |
| `nim/t/thiele_rational_interpolation.nim` | Nim ABI port |
| `odin/t/thiele_rational_interpolation.odin` | Odin ABI port |
| `rust/t/thiele_rational_interpolation.rs` | Rust ABI port |
| `v/t/thiele_rational_interpolation.v` | V ABI port |
| `zig/t/thiele_rational_interpolation.zig` | Zig ABI port |

The numerical algorithm references and discovery-only title index are listed in `README.md` and `RIGHTS.md`.
