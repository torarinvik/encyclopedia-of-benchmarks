# Static package inventory

- Algorithm: `sturmian_standard_word`
- ABI: `i64_array_bytes_output`
- Native implementations: ten, one in each supported language.
- Maximum valid/parseable input: 5/6 signed 64-bit words.
- Maximum word output: 41 ASCII bytes.
- Declared native workspace: 512 bytes, excluding caller-owned input/output.
- References: direct standard-word recurrence; letter-morphism composition.
- Workload covers the base case, directive boundaries, mixed directives,
  maximum output capacity failure, malformed input and null buffer paths.

## Native paths

- `c/s/sturmian_standard_word.c`
- `c3/s/sturmian_standard_word.c3`
- `cpp/s/sturmian_standard_word.cpp`
- `elisa/s/sturmian_standard_word.elisa`
- `mojo/s/sturmian_standard_word.mojo`
- `nim/s/sturmian_standard_word.nim`
- `odin/s/sturmian_standard_word.odin`
- `rust/s/sturmian_standard_word.rs`
- `v/s/sturmian_standard_word.v`
- `zig/s/sturmian_standard_word.zig`

## Package-local files

- `__init__.py`
- `README.md`
- `RIGHTS.md`
- `INVENTORY.md`
- `INVENTORY.json`
- `workload.json`
- `primary_oracle.py`
- `independent_oracle.py`
- `verify_workload.py`
- `check_inventory.py`

The inventory and fixture helpers are source artifacts. They have not been
executed.
