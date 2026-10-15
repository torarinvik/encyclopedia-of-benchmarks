# Excel title to column

## Contract

Convert an Excel-style column title to its one-based column number. The `i64_array_scalar` input is packed as `[length, ascii_0, ...]`, where each title character is represented by its ASCII code. Titles must contain 1 through 12 ASCII letters (`A`–`Z` or `a`–`z`); lowercase letters are treated as uppercase. A malformed packed array, empty title, title longer than 12 characters, or non-letter value returns `-1`.

For a valid title, process the letters from left to right using the base-26 recurrence `column = column * 26 + letter_value`, with `A = 1` through `Z = 26`. The 12-character bound keeps the result within signed 64-bit range. The algorithm uses O(n) time and O(1) additional space.

The upstream function accepts Unicode alphabetic strings through Python's `isalpha()`, but its `ord()` arithmetic is only coherent for the ASCII Excel alphabet. This benchmark deliberately bounds the input to ASCII so all ports share the same contract.

## Workload

[`workload.json`](workload.json) covers one-letter and multi-letter titles, mixed case, invalid characters, malformed lengths, and the empty title. Build and run with the `i64_array_scalar` ABI family:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm excel_title_to_column --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/e/excel_title_to_column/rust/build.json
```

The shared scalar-array runner validates with the source's right-to-left base-26 accumulation over the portable ASCII domain.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/excel_title_to_column.c`](../../../c/e/excel_title_to_column.c) |
| C3 | [`c3/e/excel_title_to_column.c3`](../../../c3/e/excel_title_to_column.c3) |
| C++ | [`cpp/e/excel_title_to_column.cpp`](../../../cpp/e/excel_title_to_column.cpp) |
| Elisa | [`elisa/e/excel_title_to_column.elisa`](../../../elisa/e/excel_title_to_column.elisa) |
| Nim | [`nim/e/excel_title_to_column.nim`](../../../nim/e/excel_title_to_column.nim) |
| Odin | [`odin/e/excel_title_to_column.odin`](../../../odin/e/excel_title_to_column.odin) |
| Rust | [`rust/e/excel_title_to_column.rs`](../../../rust/e/excel_title_to_column.rs) |
| V | [`v/e/excel_title_to_column.v`](../../../v/e/excel_title_to_column.v) |
| Zig | [`zig/e/excel_title_to_column.zig`](../../../zig/e/excel_title_to_column.zig) |

## TheAlgorithms reference

- [Python `excel_title_to_column.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/conversions/excel_title_to_column.py)
