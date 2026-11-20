# Static package inventory

This is a source-level inventory. The ports, workload verifier, and static
checker have not been run.

| Artifact | Purpose |
| --- | --- |
| `README.md` | D²-seeding contract, duplicate/fallback rules, local distinction, and citations |
| `RIGHTS.md` | Paper attribution and title-index discovery note |
| `workload.json` | Deterministic draw-tape fixtures and workload profiles |
| `primary_oracle.py` | Incremental nearest-distance reference |
| `independent_oracle.py` | Recomputed-distance and prefix-search reference |
| `verify_workload.py` | Optional workload/reference consistency verifier; not executed |
| `check_inventory.py` | Static port, artifact, and provenance inventory; not executed |
| Ten language files | C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig ABI ports |

Every port exports `kmeans_plus_plus_seeding` using
`i64_array_bytes_output`. The maximum valid input is 139 signed 64-bit words;
the maximum output is 64 bytes.
