# Package inventory

Algorithm: `base58check_encode`  
ABI: `i64_array_bytes_output`  
Input: `[version_byte,payload_length,payload_byte_0,...]`  
Valid input length: 2 to 34 values, exact length `2 + payload_length`  
Parseable input length: at most 35 values  
Output: Bitcoin Base58Check ASCII bytes, at most 51 bytes  
Largest native fixed scratch set: 826 bytes, including message/digest/radix buffers and the largest SHA-256 helper workspace; caller-owned input/output are excluded

## Native ports

- `c/b/base58check_encode.c`
- `c3/b/base58check_encode.c3`
- `cpp/b/base58check_encode.cpp`
- `elisa/b/base58check_encode.elisa`
- `mojo/b/base58check_encode.mojo`
- `nim/b/base58check_encode.nim`
- `odin/b/base58check_encode.odin`
- `rust/b/base58check_encode.rs`
- `v/b/base58check_encode.v`
- `zig/b/base58check_encode.zig`

## Package artifacts

- `README.md`, `RIGHTS.md`, `INVENTORY.md`, `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`, `independent_oracle.py`
- `verify_workload.py`, `check_inventory.py`, `__init__.py`

The primary oracle uses integer conversion and `divmod(58)`; the independent
reference repeatedly divides a big-endian byte array. Both use the Python
standard SHA-256 primitive for the double-digest checksum. No programs, tests,
scripts, checkers, builds, compilers, profilers, or benchmarks were run.
