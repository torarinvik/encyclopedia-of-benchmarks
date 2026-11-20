# Package inventory

| Artifact | Path |
|---|---|
| C port | `c/s/smo_deterministic_training.c` |
| C3 port | `c3/s/smo_deterministic_training.c3` |
| C++ port | `cpp/s/smo_deterministic_training.cpp` |
| Elisa port | `elisa/s/smo_deterministic_training.elisa` |
| Mojo port | `mojo/s/smo_deterministic_training.mojo` |
| Nim port | `nim/s/smo_deterministic_training.nim` |
| Odin port | `odin/s/smo_deterministic_training.odin` |
| Rust port | `rust/s/smo_deterministic_training.rs` |
| V port | `v/s/smo_deterministic_training.v` |
| Zig port | `zig/s/smo_deterministic_training.zig` |
| Primary reference | `benchmarks/smo_deterministic_training_oracle.py` |
| Independent reference | `benchmarks/smo_deterministic_training_verifier_oracle.py` |
| Workload | `benchmarks/s/smo_deterministic_training/workload.json` |
| Workload verifier | `benchmarks/s/smo_deterministic_training/verify_workload.py` |
| Static inventory | `benchmarks/s/smo_deterministic_training/check_inventory.py` |
| Rights/provenance | `benchmarks/s/smo_deterministic_training/RIGHTS.md` |
| Package README | `benchmarks/s/smo_deterministic_training/README.md` |
| Source crosswalk | `benchmarks/s/smo_deterministic_training/SOURCE_CROSSWALK.md` |

The ten source files expose `smo_deterministic_training` with the
`float64_slice_io` signature. The package is registered in the float64 slice
runner and verifier. No executable checks have been run.
