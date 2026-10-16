# Data normalization and standardization

This benchmark ports the two functions in the pinned TheAlgorithms/R script: min-max `normalization` and z-score `standardization`. The operation selector lets one ABI measure either source routine while preserving their distinct formulas.

## Contract

- Input is `[operation, sample_count, values...]`. Operation `0` selects `(x - min(x)) / (max(x) - min(x))`; operation `1` selects `(x - mean(x)) / sd(x)`.
- The benchmark specializes R’s numeric vectors to 2–128 signed integer samples in `[-100,000, 100,000]`. Constant vectors are rejected because both source expressions divide by zero; one-sample standardization is also outside the bounded domain. Invalid inputs return `-1`.
- Standardization uses the sample standard deviation with denominator `n - 1`, matching R’s `sd`. Output is one binary64 result per input value, in input order, encoded little-endian. A short output buffer returns `-2`.
- Output values are compared with absolute and relative tolerances of `1e-12`. Implementations use portable language-level floating-point operations and do not rely on CPU-specific instructions.

## Pinned source

The source defines `normalization(x) = (x - min(x)) / (max(x) - min(x))` and `standardization(x) = (x - mean(x)) / sd(x)`: [TheAlgorithms/R `data_normalization_standardization.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_preprocessing/data_normalization_standardization.r). Its demo applies the functions column-wise to the numeric columns of `iris`; this benchmark focuses on the two reusable vector transformations.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm data_normalization_standardization --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/data_normalization_standardization/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm data_normalization_standardization --language rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/d/data_normalization_standardization.c`](../../../c/d/data_normalization_standardization.c) |
| C3 | [`c3/d/data_normalization_standardization.c3`](../../../c3/d/data_normalization_standardization.c3) |
| C++ | [`cpp/d/data_normalization_standardization.cpp`](../../../cpp/d/data_normalization_standardization.cpp) |
| Elisa | [`elisa/d/data_normalization_standardization.elisa`](../../../elisa/d/data_normalization_standardization.elisa) |
| Nim | [`nim/d/data_normalization_standardization.nim`](../../../nim/d/data_normalization_standardization.nim) |
| Odin | [`odin/d/data_normalization_standardization.odin`](../../../odin/d/data_normalization_standardization.odin) |
| Rust | [`rust/d/data_normalization_standardization.rs`](../../../rust/d/data_normalization_standardization.rs) |
| V | [`v/d/data_normalization_standardization.v`](../../../v/d/data_normalization_standardization.v) |
| Zig | [`zig/d/data_normalization_standardization.zig`](../../../zig/d/data_normalization_standardization.zig) |
