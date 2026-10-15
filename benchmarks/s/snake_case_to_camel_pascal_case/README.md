# Snake case to camelCase or PascalCase

Transform a bounded ASCII `snake_case` string to camelCase or PascalCase, following the pinned Python helper's `use_pascal` option.

## Contract

- The `i64_array_bytes_output` input is `[mode, ASCII_codepoints...]`. Mode `0` selects camelCase; mode `1` selects PascalCase.
- The string contains 1..256 lowercase ASCII letters or digits, separated by single interior underscores. It cannot start or end with `_`, and repeated underscores are invalid.
- Camel mode preserves the first segment and uppercases the first lowercase letter of every later segment. Pascal mode also uppercases the first letter of the first segment. Digits at segment starts remain unchanged; all other characters are preserved.
- Success writes the transformed bytes without a terminator and returns their length. Invalid packed input returns `-1`; insufficient output capacity returns `-2`.

The lowercase alphanumeric domain makes the Python helper's ASCII `str.upper()` behavior byte-for-byte defined. The source assumes nonempty segments when it indexes each word's first character; the workload makes that precondition explicit.

## Source and workload

The source is the pinned Python [`snake_case_to_camel_pascal_case.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/snake_case_to_camel_pascal_case.py). Its default mode preserves the first word and capitalizes later words; `use_pascal=True` capitalizes every word.

[`workload.json`](workload.json) covers both modes, digit segments, single words, source examples, and invalid mode/string shapes.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/snake_case_to_camel_pascal_case.c`](../../../c/s/snake_case_to_camel_pascal_case.c) |
| C3 | [`c3/s/snake_case_to_camel_pascal_case.c3`](../../../c3/s/snake_case_to_camel_pascal_case.c3) |
| C++ | [`cpp/s/snake_case_to_camel_pascal_case.cpp`](../../../cpp/s/snake_case_to_camel_pascal_case.cpp) |
| Elisa | [`elisa/s/snake_case_to_camel_pascal_case.elisa`](../../../elisa/s/snake_case_to_camel_pascal_case.elisa) |
| Nim | [`nim/s/snake_case_to_camel_pascal_case.nim`](../../../nim/s/snake_case_to_camel_pascal_case.nim) |
| Odin | [`odin/s/snake_case_to_camel_pascal_case.odin`](../../../odin/s/snake_case_to_camel_pascal_case.odin) |
| Rust | [`rust/s/snake_case_to_camel_pascal_case.rs`](../../../rust/s/snake_case_to_camel_pascal_case.rs) |
| V | [`v/s/snake_case_to_camel_pascal_case.v`](../../../v/s/snake_case_to_camel_pascal_case.v) |
| Zig | [`zig/s/snake_case_to_camel_pascal_case.zig`](../../../zig/s/snake_case_to_camel_pascal_case.zig) |

The source-backed byte-output oracle branch is pending integration in [`benchmarks/run_i64_array_bytes_output.py`](../../run_i64_array_bytes_output.py).
