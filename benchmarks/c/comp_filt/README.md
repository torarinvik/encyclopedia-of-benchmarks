# Complementary filter trace

This package ports the pinned Haskell `compFilt` scan over gyroscope rates and accelerometer angles. The source returns a trace; the benchmark adds an output index so each call returns one selected binary64 trace value through the shared `i64_array_float64` ABI.

## Contract

- Input is `[alpha_ppm, delta_t_micro, sample_count, output_index, rates[0..n-1], accelerometer_angles[0..n-1]]`. The two sample arrays each contain `sample_count` values.
- `sample_count` is 1 through 32, and `output_index` is 0 through `sample_count`. Index 0 is the initial `head accelerometer_angles` value; index `j > 0` is the `scanl` result after the first `j` zipped pairs.
- Alpha and delta time are represented in millionths and each range from 0 through 1,000,000. Rates and angles are also in millionths and range from -1,000,000 through 1,000,000.
- The recurrence preserves source order: `theta = alpha * (theta + rate * delta_t) + (1 - alpha) * accelerometer_angle`. The first pair is applied, so the trace contains `sample_count + 1` values.
- The shared contract requires equal array lengths; malformed shapes or out-of-range values return `-1e300`. Valid values use absolute tolerance `1e-9` and relative tolerance `1e-12`.

## Workload and verification

[`workload.json`](workload.json) exercises the initial value, first and final scan steps, alpha endpoints, zero delta time, negative rates, maximum sample count, malformed lengths, and domain limits. Run the independent bounded corpus through each available language implementation with:

```sh
python3 benchmarks/verify_comp_filt.py
```

## Pinned source

- Haskell [`CompFilt.hs`](https://github.com/TheAlgorithms/Haskell/blob/9dcabef99fb8995a760ff25a9e0d659114c0b9d3/src/Robotics/ComplementaryFilter/CompFilt.hs)

The package covers the pure `compFilt` routine. The source's sample-data loader, vector accessors, accelerometer tilt conversion, and `main` demo are outside this contract.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/comp_filt.c`](../../../c/c/comp_filt.c) |
| C3 | [`c3/c/comp_filt.c3`](../../../c3/c/comp_filt.c3) |
| C++ | [`cpp/c/comp_filt.cpp`](../../../cpp/c/comp_filt.cpp) |
| Elisa | [`elisa/c/comp_filt.elisa`](../../../elisa/c/comp_filt.elisa) |
| Nim | [`nim/c/comp_filt.nim`](../../../nim/c/comp_filt.nim) |
| Odin | [`odin/c/comp_filt.odin`](../../../odin/c/comp_filt.odin) |
| Rust | [`rust/c/comp_filt.rs`](../../../rust/c/comp_filt.rs) |
| V | [`v/c/comp_filt.v`](../../../v/c/comp_filt.v) |
| Zig | [`zig/c/comp_filt.zig`](../../../zig/c/comp_filt.zig) |
