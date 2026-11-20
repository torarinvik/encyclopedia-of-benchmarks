# Package inventory

This package contains the bounded, quantized Algorithm X skip-sampling
profile. The inventory checker is source-only: importing it and calling
`static_issues()` checks package files and compares workload fixtures with the
two Python references. It does not launch benchmark programs.

| Artifact | Purpose |
| --- | --- |
| `README.md` | Contract, exact skip CDF, quantization, arithmetic bounds, and distinctions from local reservoir profiles |
| `RIGHTS.md` | Source provenance and clean-room statement |
| `workload.json` | Bounded draw-tape fixtures, ABI/output metadata, malformed and capacity cases |
| `primary_oracle.py` | Skip replay using a reduced-rational tail recurrence; exports `WORKSPACE_BYTES` |
| `independent_oracle.py` | Direct falling-factorial CDF scan, independent of the recurrence |
| `check_inventory.py` | Package-local static file/workload/reference inventory API |
| `benchmarks/check_reservoir_sampling_algorithm_x_package.py` | Repository inventory and workload fixture preflight |

| Language | Source |
| --- | --- |
| C | `c/x/reservoir_sampling_algorithm_x.c` |
| C3 | `c3/x/reservoir_sampling_algorithm_x.c3` |
| C++ | `cpp/x/reservoir_sampling_algorithm_x.cpp` |
| Elisa | `elisa/x/reservoir_sampling_algorithm_x.elisa` |
| Mojo | `mojo/x/reservoir_sampling_algorithm_x.mojo` |
| Nim | `nim/x/reservoir_sampling_algorithm_x.nim` |
| Odin | `odin/x/reservoir_sampling_algorithm_x.odin` |
| Rust | `rust/x/reservoir_sampling_algorithm_x.rs` |
| V | `v/x/reservoir_sampling_algorithm_x.v` |
| Zig | `zig/x/reservoir_sampling_algorithm_x.zig` |

No programs, tests, scripts, checkers, builds, compilers, or benchmarks have
been run.
