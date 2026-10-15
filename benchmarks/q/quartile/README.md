# Quartile

## Contract

The pinned C program generates `n` values with `rand() % 100`, sorts them by comparing and swapping pairs, then reports Q1, Q3, and the interquartile range. The benchmark replaces only the random generation with a supplied deterministic array. Input is `[n, values...]`, with `1 <= n <= 10` and each value in `0..99`, matching the source's fixed ten-element array and generated-value domain.

The source selects `q1 = sorted[n / 4]` and `q3 = sorted[(3 * n) / 4]` using integer division; `iqr = q3 - q1`. The output encodes `[n, sorted_values..., q1, q3, iqr]` as little-endian signed 64-bit integers. The return value is the encoded byte count. Malformed inputs return `-1`; an undersized output buffer returns `-2`.

The C source prints the sorted values as well as its quartile results, so the benchmark includes the sorted sequence in its output. Its `n` value is not validated before indexing a ten-element array; this contract bounds it to the safe range. The related Python `interquartile_range` candidate uses medians of the lower and upper halves, so it follows a different quartile rule and is not an alias.

## Workload and implementation

[`workload.json`](workload.json) covers singleton, odd and even sizes, duplicates, the source's sample dataset, sorted and reverse ordered inputs, and invalid cases. The `i64_array_bytes_output` ABI supports the input size and the maximum 112-byte output.

Build and run with:

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm quartile --language rust --with-checker
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/q/quartile/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/q/quartile.c`](../../../c/q/quartile.c) |
| C3 | [`c3/q/quartile.c3`](../../../c3/q/quartile.c3) |
| C++ | [`cpp/q/quartile.cpp`](../../../cpp/q/quartile.cpp) |
| Elisa | [`elisa/q/quartile.elisa`](../../../elisa/q/quartile.elisa) |
| Nim | [`nim/q/quartile.nim`](../../../nim/q/quartile.nim) |
| Odin | [`odin/q/quartile.odin`](../../../odin/q/quartile.odin) |
| Rust | [`rust/q/quartile.rs`](../../../rust/q/quartile.rs) |
| V | [`v/q/quartile.v`](../../../v/q/quartile.v) |
| Zig | [`zig/q/quartile.zig`](../../../zig/q/quartile.zig) |

## Pinned source

- [C `quartile.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/misc/quartile.c)
- [Python `interquartile_range.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/interquartile_range.py)
