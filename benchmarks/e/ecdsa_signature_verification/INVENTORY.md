# Package inventory

| Artifact | Purpose |
|---|---|
| `RESERVATION.md` | Reserved operation and exact bounded curve contract. |
| `README.md` | User-facing algorithm, validation, ABI, and complexity notes. |
| `RIGHTS.md` | Title-only discovery and clean-room provenance record. |
| `workload.json` | Valid/invalid signatures, malformed inputs, and capacity fixtures. |
| `primary_oracle.py` | EEA inversion and double-scalar ECDSA verification reference. |
| `independent_oracle.py` | Exhaustive public-scalar and nonce relation reference. |
| `verify_workload.py` | Static fixture/reference consistency checker source. |
| `check_inventory.py` | Static artifact, port-path, symbol, and workload metadata checker source. |

Native ports use the common symbol `ecdsa_signature_verification` and the
`i64_array_bytes_output` ABI:

| Language | Source |
|---|---|
| C | `c/e/ecdsa_signature_verification.c` |
| C3 | `c3/e/ecdsa_signature_verification.c3` |
| C++ | `cpp/e/ecdsa_signature_verification.cpp` |
| Elisa | `elisa/e/ecdsa_signature_verification.elisa` |
| Mojo | `mojo/e/ecdsa_signature_verification.mojo` |
| Nim | `nim/e/ecdsa_signature_verification.nim` |
| Odin | `odin/e/ecdsa_signature_verification.odin` |
| Rust | `rust/e/ecdsa_signature_verification.rs` |
| V | `v/e/ecdsa_signature_verification.v` |
| Zig | `zig/e/ecdsa_signature_verification.zig` |

The package is registered with the `i64_array_bytes_output` runner and
verifier, including generated capacity, null-pointer, and malformed-input ABI
probes. README, catalog, and shared coverage-ledger entries are integrated.
Package sources and validation helpers have not been executed or compiled.
