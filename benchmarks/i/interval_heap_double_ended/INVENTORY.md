# Package inventory

Algorithm: `interval_heap_double_ended`

ABI: `i64_array_bytes_output`

Ports: C, C3, C++, Elisa, Mojo, Nim, Odin, Rust, V, Zig.

References: `primary_oracle.py` (paired endpoint heap), `independent_oracle.py` (sorted multiset).

Bounded input: at most 64 initial signed-i32 keys, 128 operations, 192 live keys, and 322 i64 input words. Maximum output: 1,552 bytes. Maximum workspace: 8,192 bytes.

Metadata: `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`, `workload.json`, `primary_oracle.py`, `independent_oracle.py`, `check_inventory.py`.

All listed package files and ten language ports are draft artifacts. Shared suite registration and global catalog integration are owned by the parent task.
