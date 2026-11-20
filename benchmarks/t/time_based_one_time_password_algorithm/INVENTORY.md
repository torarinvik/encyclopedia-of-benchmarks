# Package inventory

- Algorithm: `time_based_one_time_password_algorithm`
- ABI: `i64_array_bytes_output`
- Native ports: [C](../../../c/t/time_based_one_time_password_algorithm.c), [C3](../../../c3/t/time_based_one_time_password_algorithm.c3), [C++](../../../cpp/t/time_based_one_time_password_algorithm.cpp), [Elisa](../../../elisa/t/time_based_one_time_password_algorithm.elisa), [Mojo](../../../mojo/t/time_based_one_time_password_algorithm.mojo), [Nim](../../../nim/t/time_based_one_time_password_algorithm.nim), [Odin](../../../odin/t/time_based_one_time_password_algorithm.odin), [Rust](../../../rust/t/time_based_one_time_password_algorithm.rs), [V](../../../v/t/time_based_one_time_password_algorithm.v), [Zig](../../../zig/t/time_based_one_time_password_algorithm.zig)
- Primary reference: `primary_oracle.py` (Python standard-library HMAC-SHA-1)
- Independent reference: `independent_oracle.py` (local SHA-1 compression and HMAC block construction)
- Workload: `workload.json`
- Workload-reference reconciliation: `verify_workload.py` (authored only; not run)
- Static path/metadata inventory: `check_inventory.py` (authored only; not run)
- Rights and source distinction: `RIGHTS.md`
- Shared suite status: integrated in the `i64_array_bytes_output` runner and verifier, README, and catalog.

The declared workspace ceiling is 1,024 bytes. The core arrays sum to 494
bytes; fixed 64-byte block arguments passed by value in some ports raise the
largest simultaneous array storage to at most 558 bytes. The remaining space
accommodates bounded scalar and index state. Caller-owned input/output storage
is excluded. All fixture outputs are pinned, and no package helper, native
port, compiler, or test has been executed.
