# Static source inventory

This inventory describes files only. No benchmark, test, checker, script,
compiler, or build was run.

| Artifact | Purpose |
| --- | --- |
| `README.md` | Bounded polygon-area contract, local distinction, and citations |
| `RIGHTS.md` | Attribution, discovery provenance, and clean-room note |
| `workload.json` | Expected scalar outcomes and measurement profile |
| `primary_oracle.py` | Chord/apothem recurrence reference |
| `independent_oracle.py` | Direct central-angle polygon-area reference |
| `verify_workload.py` | Optional static fixture/reference consistency review; not run |
| `check_inventory.py` | Static files, symbol, and provenance inventory; not run |
| Ten language files | C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig exports |

The intended ABI is a pointer to signed 64-bit values, a `size_t` length, and
one signed 64-bit scalar result. The scalar runner/verifier frame the input as
`[doublings]` and cover empty, null-pointer, and wrong-length cases.
