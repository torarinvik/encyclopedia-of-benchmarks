# Package inventory

The package contains the bounded input/output contract and fixture set in
`workload.json`, the paper-faithful five-tuple DAG reference in
`primary_oracle.py`, and a structurally independent subset/private-neighbor
reference in `independent_oracle.py`. `verify_workload.py` statically compares
the pinned fixtures against both references. `check_inventory.py` checks the
declared package artifacts and ten native-language source paths without
building or invoking them.

The language inventory is the ten-path map in `INVENTORY.json`: C, C3, C++,
Elisa, Mojo, Nim, Odin, Rust, V, and Zig. Native workspace is capped at
1,048,576 bytes. The largest primary table is 59,049 signed-i64 path counts
(472,392 bytes); successors are generated on demand rather than kept as an
arc list.

Source provenance and clean-room scope are recorded in `README.md` and
`RIGHTS.md`. The package is registered with the shared scalar runner,
independent verifier, and catalog.
