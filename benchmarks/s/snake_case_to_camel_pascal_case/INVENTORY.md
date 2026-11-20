# Static package inventory

- Algorithm: `snake_case_to_camel_pascal_case`
- ABI: `i64_array_bytes_output`
- Native implementations: ten, one in each supported language.
- Input: mode `0` for camelCase or `1` for PascalCase, then 1–256 lowercase
  ASCII letters or digits separated by single interior underscores.
- Maximum valid input: 257 signed 64-bit values; maximum parseable input: 258
  values, allowing an overlength frame to be rejected.
- Maximum output and declared workspace: 256 bytes.
- References: one source-shaped transducer and an independent split/join
  implementation.
- Workload: source examples, both output modes, digits at word starts,
  single-word inputs, malformed mode/string shapes, and output-capacity error.

## Native paths

- `c/s/snake_case_to_camel_pascal_case.c`
- `c3/s/snake_case_to_camel_pascal_case.c3`
- `cpp/s/snake_case_to_camel_pascal_case.cpp`
- `elisa/s/snake_case_to_camel_pascal_case.elisa`
- `mojo/s/snake_case_to_camel_pascal_case.mojo`
- `nim/s/snake_case_to_camel_pascal_case.nim`
- `odin/s/snake_case_to_camel_pascal_case.odin`
- `rust/s/snake_case_to_camel_pascal_case.rs`
- `v/s/snake_case_to_camel_pascal_case.v`
- `zig/s/snake_case_to_camel_pascal_case.zig`

The inventory and workload helpers are source artifacts and have not been run.
