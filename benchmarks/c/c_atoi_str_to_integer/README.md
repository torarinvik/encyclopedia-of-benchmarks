# C atoi string to integer

## Contract

Input is an array of 0 through 4,096 ASCII byte values, each in `[0, 127]`. Invalid array lengths or byte values return `-2`. Parsing stops at the first NUL byte; later valid ASCII bytes are ignored. Before that terminator, the parser skips the six ASCII whitespace bytes: space and `0x09` through `0x0d`. It then consumes one optional sign and the longest initial run of decimal digits. If no digits follow, return `0`.

Results saturate at the signed 32-bit bounds. The pinned C source returns `int` but accumulates in `long`; its overflow checks do not define portable behavior at the `long` or `int` boundaries. This benchmark specifies saturation so all nine implementations have a stable result. The parser core is related to [`string_to_integer`](../string_to_integer/README.md), but the accepted whitespace and NUL-termination rules make this a separate contract.

## Workload and reproduction

The workload covers signs, each C ASCII whitespace class, stopping at nondigits, NUL termination, no-digit inputs, both signed 32-bit bounds, overflow, invalid bytes, and maximum input length.

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm c_atoi_str_to_integer --language rust --with-checker
python3 benchmarks/run_i64_array_scalar.py --build-manifest build/i64_array_scalar/c/c_atoi_str_to_integer/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/c_atoi_str_to_integer.c`](../../../c/c/c_atoi_str_to_integer.c) |
| C3 | [`c3/c/c_atoi_str_to_integer.c3`](../../../c3/c/c_atoi_str_to_integer.c3) |
| C++ | [`cpp/c/c_atoi_str_to_integer.cpp`](../../../cpp/c/c_atoi_str_to_integer.cpp) |
| Elisa | [`elisa/c/c_atoi_str_to_integer.elisa`](../../../elisa/c/c_atoi_str_to_integer.elisa) |
| Nim | [`nim/c/c_atoi_str_to_integer.nim`](../../../nim/c/c_atoi_str_to_integer.nim) |
| Odin | [`odin/c/c_atoi_str_to_integer.odin`](../../../odin/c/c_atoi_str_to_integer.odin) |
| Rust | [`rust/c/c_atoi_str_to_integer.rs`](../../../rust/c/c_atoi_str_to_integer.rs) |
| V | [`v/c/c_atoi_str_to_integer.v`](../../../v/c/c_atoi_str_to_integer.v) |
| Zig | [`zig/c/c_atoi_str_to_integer.zig`](../../../zig/c/c_atoi_str_to_integer.zig) |

## TheAlgorithms reference

- [C `c_atoi_str_to_integer.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/c_atoi_str_to_integer.c)
