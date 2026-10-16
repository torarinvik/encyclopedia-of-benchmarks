# Harmonic series

The pinned Python `harmonic_series(n_term)` converts its argument to an integer and returns the list `['1', '1/2', ..., '1/n']`. For this bounded benchmark, the input is an integer and the returned list is encoded as newline-delimited ASCII.

## Contract

- The `i64_scalar_bytes_output` ABI accepts a signed integer from -512 through 512. Values outside the range return `-1`.
- A positive input `n` returns `1\n`, followed by `1/2\n` through `1/n\n`. Inputs at or below zero return an empty byte string, matching the source's empty list.
- The return value is the number of output bytes. Insufficient capacity returns `-2` without writing; the maximum output is 2,962 bytes.

[`workload.json`](workload.json) covers empty, single-term, multi-digit denominator, maximum-length, and out-of-range inputs.

```sh
python3 benchmarks/build_abi.py --family i64_scalar_bytes_output --algorithm harmonic_series --language rust
python3 benchmarks/run_i64_scalar_bytes_output.py --build-manifest build/i64_scalar_bytes_output/h/harmonic_series/rust/build.json
```

| Language | Source |
| --- | --- |
| C | [`c/h/harmonic_series.c`](../../../c/h/harmonic_series.c) |
| C3 | [`c3/h/harmonic_series.c3`](../../../c3/h/harmonic_series.c3) |
| C++ | [`cpp/h/harmonic_series.cpp`](../../../cpp/h/harmonic_series.cpp) |
| Elisa | [`elisa/h/harmonic_series.elisa`](../../../elisa/h/harmonic_series.elisa) |
| Nim | [`nim/h/harmonic_series.nim`](../../../nim/h/harmonic_series.nim) |
| Odin | [`odin/h/harmonic_series.odin`](../../../odin/h/harmonic_series.odin) |
| Rust | [`rust/h/harmonic_series.rs`](../../../rust/h/harmonic_series.rs) |
| V | [`v/h/harmonic_series.v`](../../../v/h/harmonic_series.v) |
| Zig | [`zig/h/harmonic_series.zig`](../../../zig/h/harmonic_series.zig) |

## TheAlgorithms reference

- [Python `harmonic_series.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/series/harmonic_series.py)
