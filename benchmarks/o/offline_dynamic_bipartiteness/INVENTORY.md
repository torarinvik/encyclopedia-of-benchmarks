# Static inventory

`static_inventory.py` reads the package workload, rights/provenance, README,
two reference paths, and all ten language source paths. It checks the expected
metadata and source symbol names without compiling or running the ports.

| Artifact | Path |
|---|---|
| Workload | [`workload.json`](workload.json) |
| Primary rollback-parity reference | [`../../offline_dynamic_bipartiteness_oracle.py`](../../offline_dynamic_bipartiteness_oracle.py) |
| Independent graph-rebuild reference | [`independent_bfs_reference.py`](independent_bfs_reference.py) |
| Rights and source provenance | [`RIGHTS.md`](RIGHTS.md) |
| Package guide | [`README.md`](README.md) |
| Static inventory source | [`static_inventory.py`](static_inventory.py) |
| C / C3 / C++ / Elisa / Mojo | `c/o/`, `c3/o/`, `cpp/o/`, `elisa/o/`, `mojo/o/` |
| Nim / Odin / Rust / V / Zig | `nim/o/`, `odin/o/`, `rust/o/`, `v/o/`, `zig/o/` |
