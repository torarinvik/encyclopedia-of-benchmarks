# Multiplexer

This package implements the pinned Python `mux(input0, input1, select)` operation as a bounded 2-to-1 Boolean multiplexer. When `select` is 0 it returns `input0`; when `select` is 1 it returns `input1`.

## Contract

The `i64_array_scalar` input contains exactly three signed 64-bit integer values in `[input0, input1, select]` order. Every value must be exactly 0 or 1. The function returns the selected bit and returns -1 for a null input pointer, incorrect input length, or any value outside `{0, 1}`. The workload includes all eight truth-table rows, invalid values in each slot, malformed lengths, and a null-pointer call with declared length 3.

The Python source checks membership in `(0, 1)`, so values equal to these integers such as `True` and `1.0` also pass that source check. This benchmark deliberately restricts the ABI to exact signed-integer bits, as recorded in the catalog contract.

Pinned source: [TheAlgorithms/Python `boolean_algebra/multiplexer.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/boolean_algebra/multiplexer.py), commit `e1a2a8b016001309a73d5fec4818c35cca139795`, function `mux`.

The independent bounded oracle is [multiplexer_oracle.py](../../multiplexer_oracle.py); the complete workload is [workload.json](workload.json).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/m/multiplexer.c](../../../c/m/multiplexer.c) |
| C3 | [c3/m/multiplexer.c3](../../../c3/m/multiplexer.c3) |
| C++ | [cpp/m/multiplexer.cpp](../../../cpp/m/multiplexer.cpp) |
| Elisa | [elisa/m/multiplexer.elisa](../../../elisa/m/multiplexer.elisa) |
| Nim | [nim/m/multiplexer.nim](../../../nim/m/multiplexer.nim) |
| Odin | [odin/m/multiplexer.odin](../../../odin/m/multiplexer.odin) |
| Rust | [rust/m/multiplexer.rs](../../../rust/m/multiplexer.rs) |
| V | [v/m/multiplexer.v](../../../v/m/multiplexer.v) |
| Zig | [zig/m/multiplexer.zig](../../../zig/m/multiplexer.zig) |

Build a selected port with:

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm multiplexer --language rust
```

Record with:

```sh
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/m/multiplexer/rust/build.json
```

Verify with:

```sh
python3 benchmarks/verify_i64_array_scalar.py --algorithm multiplexer --languages rust
```
