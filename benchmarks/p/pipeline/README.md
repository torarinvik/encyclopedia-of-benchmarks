# Pipeline

Apply a sequence of unary stages from left to right, carrying each stage's result into the next stage.

## Contract

- The `i64_array_scalar` input is `[initial, stage_count, (operation, argument) * stage_count]`.
- `initial` and each argument are in `0..=2`; `stage_count` is in `1..=32`; operation `0` adds its argument and operation `1` multiplies by its argument.
- The input must contain exactly `2 + 2 * stage_count` signed 64-bit values. Invalid shape, operation, or range returns `-1`.
- Stages execute in listed order. The largest possible result is `2 * 2^32 = 8,589,934,592`, which fits in signed 64-bit arithmetic.
- Empty pipelines are invalid. A null input pointer is invalid at every length.
- The pinned Python source's `f_ls_` override is excluded; this benchmark covers the ordinary pipeline composition behavior.

## Workload and source

[`workload.json`](workload.json) covers order-sensitive compositions, identity and zero behavior, the maximum stage count, malformed shapes and values, and a null input pointer. [`benchmarks/pipeline_oracle.py`](../../pipeline_oracle.py) is an independent bounded oracle.

The algorithm is based on Python [`other/pipeline.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/other/pipeline.py), whose pipeline appends functions through `|` and applies the stored functions in order when called.

| Language | Source |
| --- | --- |
| C | [c/p/pipeline.c](../../../c/p/pipeline.c) |
| C3 | [c3/p/pipeline.c3](../../../c3/p/pipeline.c3) |
| C++ | [cpp/p/pipeline.cpp](../../../cpp/p/pipeline.cpp) |
| Elisa | [elisa/p/pipeline.elisa](../../../elisa/p/pipeline.elisa) |
| Nim | [nim/p/pipeline.nim](../../../nim/p/pipeline.nim) |
| Odin | [odin/p/pipeline.odin](../../../odin/p/pipeline.odin) |
| Rust | [rust/p/pipeline.rs](../../../rust/p/pipeline.rs) |
| V | [v/p/pipeline.v](../../../v/p/pipeline.v) |
| Zig | [zig/p/pipeline.zig](../../../zig/p/pipeline.zig) |

Build with the shared `i64_array_scalar` ABI family and record with `benchmarks/run_i64_array_scalar.py`.
