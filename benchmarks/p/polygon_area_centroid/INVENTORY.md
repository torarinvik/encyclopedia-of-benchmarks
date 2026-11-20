# Static package inventory

This is a source-level inventory. No port, test, workload verifier, static
checker, compiler, or build was run.

| Artifact | Purpose |
| --- | --- |
| `README.md` | Exact bounded centroid contract, local distinction, and source notes |
| `RIGHTS.md` | Mathematical attribution and discovery-only provenance |
| `workload.json` | Valid, malformed, buffer, and rounding fixtures |
| `primary_oracle.py` | Shoelace cross-sum centroid reference |
| `independent_oracle.py` | Signed triangle-fan area-weighted centroid reference |
| `verify_workload.py` | Optional reference/fixture consistency source; not run |
| `check_inventory.py` | Static artifact and port inventory; not run |
| Ten language files | C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig ABI ports |

The intended ABI is `i64_array_bytes_output`; success returns 16 bytes holding
two signed little-endian i64 coordinates in millionths.
