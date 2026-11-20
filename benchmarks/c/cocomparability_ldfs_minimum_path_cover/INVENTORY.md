# Package inventory

- `README.md` — bounded contract, method, duplicate rationale, and sources.
- `RIGHTS.md` — provenance and clean-room statement.
- `workload.json` — pinned inputs, expected scalar results, and suite bounds.
- `primary_oracle.py` — LDFS+ followed by RMN path-count reference.
- `independent_oracle.py` — subset path-existence and minimum-partition reference.
- `verify_workload.py` — static inventory and pinned-reference review helpers.
- `i64_array_scalar` runner/verifier registration and catalog entry are present.
- Ten native sources:
  `c/c/cocomparability_ldfs_minimum_path_cover.c`,
  `c3/c/cocomparability_ldfs_minimum_path_cover.c3`,
  `cpp/c/cocomparability_ldfs_minimum_path_cover.cpp`,
  `elisa/c/cocomparability_ldfs_minimum_path_cover.elisa`,
  `mojo/c/cocomparability_ldfs_minimum_path_cover.mojo`,
  `nim/c/cocomparability_ldfs_minimum_path_cover.nim`,
  `odin/c/cocomparability_ldfs_minimum_path_cover.odin`,
  `rust/c/cocomparability_ldfs_minimum_path_cover.rs`,
  `v/c/cocomparability_ldfs_minimum_path_cover.v`, and
  `zig/c/cocomparability_ldfs_minimum_path_cover.zig`.
