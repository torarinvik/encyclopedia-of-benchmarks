# Excess-3 Code

This benchmark ports the pinned Python decimal-digit encoder. It clamps negative inputs to zero, then adds three to each decimal digit and writes the resulting four-bit nibbles after the source's `0b` prefix. Leading zeroes in the input are not represented because the input is an integer.

Every signed 64-bit input is accepted, including negative values and the signed boundaries. The output is ASCII and fits the 8,192-byte caller buffer. Each implementation writes into that caller-owned buffer and returns its byte length; insufficient capacity returns -2.

## Build

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm excess_3_code --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/e/excess_3_code/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/e/excess_3_code.c`](../../../c/e/excess_3_code.c) |
| C3 | [`c3/e/excess_3_code.c3`](../../../c3/e/excess_3_code.c3) |
| C++ | [`cpp/e/excess_3_code.cpp`](../../../cpp/e/excess_3_code.cpp) |
| Elisa | [`elisa/e/excess_3_code.elisa`](../../../elisa/e/excess_3_code.elisa) |
| Nim | [`nim/e/excess_3_code.nim`](../../../nim/e/excess_3_code.nim) |
| Odin | [`odin/e/excess_3_code.odin`](../../../odin/e/excess_3_code.odin) |
| Rust | [`rust/e/excess_3_code.rs`](../../../rust/e/excess_3_code.rs) |
| V | [`v/e/excess_3_code.v`](../../../v/e/excess_3_code.v) |
| Zig | [`zig/e/excess_3_code.zig`](../../../zig/e/excess_3_code.zig) |

## Pinned source

- Python [`bit_manipulation/excess_3_code.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/bit_manipulation/excess_3_code.py)
