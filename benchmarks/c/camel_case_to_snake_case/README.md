# Camel case to snake case

Convert a nonempty ASCII letter string from camelCase or PascalCase to snake_case. The input is an array of ASCII code values in the range `A`–`Z` or `a`–`z`, with length 1 through 256. Insert `_` before every uppercase letter except at position zero, and convert each uppercase letter to lowercase. Existing lowercase letters are preserved. Consecutive uppercase letters each receive an underscore, so `HTTPServer` becomes `h_t_t_p_server`.

This bounded contract captures the pinned Python transformation on a common ASCII-letter domain. It is distinct from `check_camel_case`, which only checks a predicate, and from `snake_case_to_camel_pascal_case`, which performs the inverse conversion.

The ABI is `int64_t camel_case_to_snake_case(const int64_t *input, size_t length, uint8_t *output, size_t capacity)`. Invalid input returns `-1`; insufficient output capacity returns `-2`; success writes the complete ASCII result without a terminator and returns its byte length.

## Workload

[`workload.json`](workload.json) covers camelCase and PascalCase inputs, all-lowercase and all-uppercase strings, consecutive capitals, one-letter inputs, invalid empty input, non-letter ASCII, non-ASCII values, negative values, and the input length bound.

The source-backed byte-output oracle will be added to `benchmarks/run_i64_array_bytes_output.py` by the integration queue. After that branch is present, build with the `i64_array_bytes_output` ABI family and record with the byte-output runner.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/camel_case_to_snake_case.c`](../../../c/c/camel_case_to_snake_case.c) |
| C3 | [`c3/c/camel_case_to_snake_case.c3`](../../../c3/c/camel_case_to_snake_case.c3) |
| C++ | [`cpp/c/camel_case_to_snake_case.cpp`](../../../cpp/c/camel_case_to_snake_case.cpp) |
| Elisa | [`elisa/c/camel_case_to_snake_case.elisa`](../../../elisa/c/camel_case_to_snake_case.elisa) |
| Nim | [`nim/c/camel_case_to_snake_case.nim`](../../../nim/c/camel_case_to_snake_case.nim) |
| Odin | [`odin/c/camel_case_to_snake_case.odin`](../../../odin/c/camel_case_to_snake_case.odin) |
| Rust | [`rust/c/camel_case_to_snake_case.rs`](../../../rust/c/camel_case_to_snake_case.rs) |
| V | [`v/c/camel_case_to_snake_case.v`](../../../v/c/camel_case_to_snake_case.v) |
| Zig | [`zig/c/camel_case_to_snake_case.zig`](../../../zig/c/camel_case_to_snake_case.zig) |

## Upstream reference

- [TheAlgorithms/Python `camel_case_to_snake_case.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/camel_case_to_snake_case.py)
