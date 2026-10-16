# Logarithmic series

The pinned Python `logarithmic_series(x_value, n_terms=5, expand=False)` returns symbolic expression strings by default. This bounded ABI fixes `expand` to `false`, accepts integral `x_value`, and writes one returned list item per ASCII line. The source's string cleanup for negative `x_value - 1` is preserved: for `x_value = -3`, its first five terms are `-(4^1)/1`, `(4^2)/2`, `-(4^3)/3`, `(4^4)/4`, and `-(4^5)/5`.

## Contract

- The `i64_array_bytes_output` ABI accepts exactly `[x_value, n_terms]`.
- `x_value` is bounded to -10 through 10, and `n_terms` to -64 through 256. Invalid bounds or array length return `-1`.
- Nonpositive term counts return an empty byte string. Positive counts emit the pinned symbolic expressions with a newline after each item. Inputs `[3, 5]` begin `(2^1)/1\n-(2^2)/2\n(2^3)/3\n`.
- Insufficient output capacity returns `-2` without writing. The largest bounded output is 3,240 bytes.

[`workload.json`](workload.json) covers positive and negative bases, zero, empty series, the maximum term count, invalid inputs, and a one-byte-short output-capacity case.

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm logarithmic_series --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/l/logarithmic_series/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm logarithmic_series
```

| Language | Source |
| --- | --- |
| C | [`c/l/logarithmic_series.c`](../../../c/l/logarithmic_series.c) |
| C3 | [`c3/l/logarithmic_series.c3`](../../../c3/l/logarithmic_series.c3) |
| C++ | [`cpp/l/logarithmic_series.cpp`](../../../cpp/l/logarithmic_series.cpp) |
| Elisa | [`elisa/l/logarithmic_series.elisa`](../../../elisa/l/logarithmic_series.elisa) |
| Nim | [`nim/l/logarithmic_series.nim`](../../../nim/l/logarithmic_series.nim) |
| Odin | [`odin/l/logarithmic_series.odin`](../../../odin/l/logarithmic_series.odin) |
| Rust | [`rust/l/logarithmic_series.rs`](../../../rust/l/logarithmic_series.rs) |
| V | [`v/l/logarithmic_series.v`](../../../v/l/logarithmic_series.v) |
| Zig | [`zig/l/logarithmic_series.zig`](../../../zig/l/logarithmic_series.zig) |

## TheAlgorithms reference

- [Python `logarithmic_series.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/logarithmic_series.py)
