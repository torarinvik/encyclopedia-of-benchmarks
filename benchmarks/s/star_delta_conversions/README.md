# Star-delta conversions

## Contract

Convert three positive real impedances between star (Y) and delta (Δ) arrangements. The input is `[operation, A, B, C]`, with operation `0` for star-to-delta and `1` for delta-to-star; impedance values are fixed-thousandths integers from 1,000 through 100,000. The star-to-delta outputs are `[(AB+BC+CA)/A, (AB+BC+CA)/B, (AB+BC+CA)/C]`; delta-to-star outputs are `[BC/(A+B+C), CA/(A+B+C), AB/(A+B+C)]`.

Each output is rounded to the nearest thousandth using `floor(value + 0.5)`, encoded as a signed 64-bit integer in little-endian byte order, and folded into an FNV-1a 64-bit hash returned as signed i64. `-1` marks invalid input. The contract scopes the source's complex-valued API to positive real impedances; its zero and negative-resistance exception cases are outside the benchmark domain.

The C ABI entry point is:

```c
int64_t star_delta_conversions(const int64_t *values, size_t length);
```

## Workload

[`workload.json`](workload.json) contains both conversion directions, symmetric and unequal values, and invalid operation/zero cases. Expected values come from the source-derived [runtime oracle](../../star_delta_conversions_oracle.py). The benchmark uses `i64_array_scalar` and [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/star_delta_conversions.c`](../../../c/s/star_delta_conversions.c) |
| C3 | [`c3/s/star_delta_conversions.c3`](../../../c3/s/star_delta_conversions.c3) |
| C++ | [`cpp/s/star_delta_conversions.cpp`](../../../cpp/s/star_delta_conversions.cpp) |
| Elisa | [`elisa/s/star_delta_conversions.elisa`](../../../elisa/s/star_delta_conversions.elisa) |
| Nim | [`nim/s/star_delta_conversions.nim`](../../../nim/s/star_delta_conversions.nim) |
| Odin | [`odin/s/star_delta_conversions.odin`](../../../odin/s/star_delta_conversions.odin) |
| Rust | [`rust/s/star_delta_conversions.rs`](../../../rust/s/star_delta_conversions.rs) |
| V | [`v/s/star_delta_conversions.v`](../../../v/s/star_delta_conversions.v) |
| Zig | [`zig/s/star_delta_conversions.zig`](../../../zig/s/star_delta_conversions.zig) |

## Pinned source

[Python `star_delta_conversions.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/star_delta_conversions.py)
