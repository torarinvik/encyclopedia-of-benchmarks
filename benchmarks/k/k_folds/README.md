# K-fold labels

This benchmark captures the deterministic `isList = FALSE` branch of the pinned R `get_k_folds` function. It assigns sample positions to consecutive folds using a block width of `ceiling(sample_count / fold_count)`.

## Contract

- Input is the signed 64-bit pair `[sample_count, fold_count]`, with both values in `1..12`.
- Sample positions are one-based. Position `i` receives label `floor((i - 1) / ceiling(sample_count / fold_count)) + 1`, matching the source's non-list branch.
- The result stores `sample_count` starting at bit 48, then packs each fold label into a four-bit slot in sample order, beginning at bit 0.
- Invalid input returns `-1`.

The R source seeds and samples a permutation before branching, but this branch does not use that permutation in its returned labels. The benchmark fixes the observable deterministic mode and excludes the list-returning shuffled mode.

## Workload and implementation

[`workload.json`](workload.json) covers evenly sized folds, a short final fold, more folds than samples, one fold, a single sample, and invalid inputs. The nine ports use the `i64_array_scalar` ABI family. [`k_folds_oracle.py`](../../k_folds_oracle.py) independently packs the deterministic labels into the scalar result.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm k_folds --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm k_folds
python3 benchmarks/verify_i64_array_scalar.py --algorithms k_folds
```

## Pinned source

[R `k_folds.r`](https://github.com/TheAlgorithms/R/blob/f65344fabeea0ae33c1ca321af709447c1a8a4c2/data_preprocessing/k_folds.r)

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/k/k_folds.c`](../../../c/k/k_folds.c) |
| C3 | [`c3/k/k_folds.c3`](../../../c3/k/k_folds.c3) |
| C++ | [`cpp/k/k_folds.cpp`](../../../cpp/k/k_folds.cpp) |
| Elisa | [`elisa/k/k_folds.elisa`](../../../elisa/k/k_folds.elisa) |
| Nim | [`nim/k/k_folds.nim`](../../../nim/k/k_folds.nim) |
| Odin | [`odin/k/k_folds.odin`](../../../odin/k/k_folds.odin) |
| Rust | [`rust/k/k_folds.rs`](../../../rust/k/k_folds.rs) |
| V | [`v/k/k_folds.v`](../../../v/k/k_folds.v) |
| Zig | [`zig/k/k_folds.zig`](../../../zig/k/k_folds.zig) |
