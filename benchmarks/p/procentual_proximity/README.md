# Percentual proximity scoring

This benchmark follows `procentual_proximity` from the pinned Python scoring module. It normalizes each input column to `[0, 1]`, flips the normalized score when lower values are preferred, sums column scores from left to right, and appends that total to each original row.

## Contract

- The `i64_array_bytes_output` input is `[row_count, column_count, weights_by_column..., row_major_values...]`.
- `row_count` is `1..=64`; `column_count` is `1..=8`; there is exactly one binary weight (`0` or `1`) per column; and the packed length is exactly `2 + column_count + row_count * column_count`.
- Matrix values are signed integers in `[-10,000, 10,000]`. Rows are read in row-major order. Weight `0` means lower values score higher; weight `1` means higher values score higher.
- For each column, a weight-`0` value receives `1 - ((value - minimum) / (maximum - minimum))`; a weight-`1` value receives `(value - minimum) / (maximum - minimum)`. A constant column contributes `1` for weight `0` and `0` for weight `1`.
- The per-row total is accumulated in column order. The output is a float64 vector in row-major order: each original row's values (converted exactly to binary64), followed immediately by that row's total. Every element is little-endian IEEE-754 binary64; there is no count prefix. Success returns the byte length, `row_count * (column_count + 1) * 8`.
- Invalid input returns `-1`. A null output pointer or short capacity returns `-2` and writes nothing. The maximum input length is 522 values and maximum output workspace is 4,608 bytes.

The bounded integer domain keeps all source conversions to Python `float` exact before normalization and avoids overflow. The workload includes both preference directions, constant columns, the pinned source example, the full matrix/output bounds, and malformed framing/capacity cases. Float64 outputs use absolute and relative tolerances of `1e-12` to cover equivalent IEEE-754 evaluation across the nine ports.

## Pinned source

The benchmark isolates `procentual_proximity` from [TheAlgorithms/Python `scoring_algorithm.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/scoring_algorithm.py). The source helper transposes rows into columns, applies the weight-specific normalization, sums scores in column order, then appends each score to the corresponding input row. The ABI represents the returned rows as a flat float64 vector, preserving that row-major order.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm procentual_proximity --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/p/procentual_proximity/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm procentual_proximity --language rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/p/procentual_proximity.c`](../../../c/p/procentual_proximity.c) |
| C3 | [`c3/p/procentual_proximity.c3`](../../../c3/p/procentual_proximity.c3) |
| C++ | [`cpp/p/procentual_proximity.cpp`](../../../cpp/p/procentual_proximity.cpp) |
| Elisa | [`elisa/p/procentual_proximity.elisa`](../../../elisa/p/procentual_proximity.elisa) |
| Nim | [`nim/p/procentual_proximity.nim`](../../../nim/p/procentual_proximity.nim) |
| Odin | [`odin/p/procentual_proximity.odin`](../../../odin/p/procentual_proximity.odin) |
| Rust | [`rust/p/procentual_proximity.rs`](../../../rust/p/procentual_proximity.rs) |
| V | [`v/p/procentual_proximity.v`](../../../v/p/procentual_proximity.v) |
| Zig | [`zig/p/procentual_proximity.zig`](../../../zig/p/procentual_proximity.zig) |
