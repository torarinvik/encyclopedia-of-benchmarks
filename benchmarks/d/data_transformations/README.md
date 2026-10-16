# Data transformations

This benchmark ports the pinned Python `normalization` and `standardization` functions. It keeps a separate package from the similarly named R benchmark because Python rounds every returned value to three decimal places.

## Contract

- Input is `[operation, sample_count, values...]`. Operation `0` applies min-max normalization; operation `1` applies z-score standardization.
- The benchmark specializes Python numeric lists to 2–128 signed integer samples in `[-100,000, 100,000]`. Constant samples are invalid because both source formulas divide by zero. Invalid inputs return `-1`.
- Standardization uses the sample standard deviation (`n - 1` denominator), matching `statistics.stdev`. Every output is rounded to three decimal places using Python's ties-to-even rule, then encoded as little-endian binary64 in input order. An output buffer shorter than the result returns `-2`.
- Floating results are compared with absolute and relative tolerances of `1e-12`. The implementations use portable binary64 operations and integer bit handling; they do not require architecture-specific instructions.

## Pinned source

The source defines normalization as `(x - min(data)) / (max(data) - min(data))` and standardization as `(x - mean(data)) / stdev(data)`, applying `round(..., ndigits)` with a default of three digits. See [TheAlgorithms/Python `data_transformations.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/machine_learning/data_transformations.py).

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm data_transformations --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/data_transformations/rust/build.json
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/d/data_transformations.c`](../../../c/d/data_transformations.c) |
| C3 | [`c3/d/data_transformations.c3`](../../../c3/d/data_transformations.c3) |
| C++ | [`cpp/d/data_transformations.cpp`](../../../cpp/d/data_transformations.cpp) |
| Elisa | [`elisa/d/data_transformations.elisa`](../../../elisa/d/data_transformations.elisa) |
| Nim | [`nim/d/data_transformations.nim`](../../../nim/d/data_transformations.nim) |
| Odin | [`odin/d/data_transformations.odin`](../../../odin/d/data_transformations.odin) |
| Rust | [`rust/d/data_transformations.rs`](../../../rust/d/data_transformations.rs) |
| V | [`v/d/data_transformations.v`](../../../v/d/data_transformations.v) |
| Zig | [`zig/d/data_transformations.zig`](../../../zig/d/data_transformations.zig) |
