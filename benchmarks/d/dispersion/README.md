# Population dispersion

This package benchmarks the `variance` and `stdev` functions from the pinned Haskell `Statistics.Dispersion` module. It reports population variance and population standard deviation together.

## Contract

- The `i64_array_bytes_output` input is a raw signed 64-bit integer vector; its length is the sample count. Length must be 1–128 and each value must be in `[-10,000, 10,000]`. The bounded nonempty domain avoids the source's division by zero on an empty collection.
- Compute the arithmetic mean, then the population variance `sum((x - mean)^2) / n`, followed by its square root. The denominator is `n`, not `n - 1`.
- Return `[population_variance, population_standard_deviation]` as two little-endian IEEE-754 binary64 values. Success returns 16 bytes. Float outputs use absolute and relative tolerances of `1e-12`.
- Invalid lengths or values return `-1`. A null output buffer or a capacity below 16 bytes returns `-2`.

The Haskell source is generic over foldable fractional collections; this benchmark specializes it to bounded integer samples while preserving the population formulas and result order.

## Pinned source

[TheAlgorithms/Haskell `Statistics.Dispersion`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Statistics/Dispersion.hs) defines `variance` as the mean squared deviation from the arithmetic mean and `stdev` as its square root. [`workload.json`](workload.json) covers singleton and constant samples, fractional variances, symmetric and boundary values, invalid inputs, and a short output buffer.

## Build, record, and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm dispersion --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/d/dispersion/rust/build.json
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm dispersion --language rust
```

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/d/dispersion.c`](../../../c/d/dispersion.c) |
| C3 | [`c3/d/dispersion.c3`](../../../c3/d/dispersion.c3) |
| C++ | [`cpp/d/dispersion.cpp`](../../../cpp/d/dispersion.cpp) |
| Elisa | [`elisa/d/dispersion.elisa`](../../../elisa/d/dispersion.elisa) |
| Nim | [`nim/d/dispersion.nim`](../../../nim/d/dispersion.nim) |
| Odin | [`odin/d/dispersion.odin`](../../../odin/d/dispersion.odin) |
| Rust | [`rust/d/dispersion.rs`](../../../rust/d/dispersion.rs) |
| V | [`v/d/dispersion.v`](../../../v/d/dispersion.v) |
| Zig | [`zig/d/dispersion.zig`](../../../zig/d/dispersion.zig) |
