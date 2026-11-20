# Package inventory

- Algorithm: `rodrigues_arbitrary_axis_rotation`
- ABI: `float64_slice_io`
- Contract: exactly seven input doubles; three output doubles; 256-byte workspace cap.
- References: vector-form primary oracle and matrix-form independent oracle.
- Workload: `workload.json`.
- Provenance: see `RIGHTS.md` and the source discussion in `README.md`.
- Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, and Zig.
- Shared runner, catalog, and coverage registration: complete in `float64_slice_io`.
