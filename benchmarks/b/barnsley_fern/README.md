# Barnsley Fern

This benchmark ports the four affine maps and probability thresholds from the pinned Python Barnsley fern. It accepts an explicit deterministic sample stream so every language follows the same map sequence without depending on Python's `random.Random` or plotting libraries.

## Contract

- Input is `[iteration_count, sample_bin_0, ...]`. Iteration count is 1 through 4,096; there is one sample bin per point after the initial origin. Each bin is 0 through 9,999 and represents a sample in `[0,1)` at resolution 1/10,000.
- The source thresholds select the stem for bins 0–99, the main leaflet for 100–8,599, the left leaflet for 8,600–9,299, and the right leaflet for 9,300–9,999.
- Coordinates use signed Q12 fixed point during the affine steps, with nearest-even division to match the source's 12-decimal rounding. Output contains every point, including the origin, as Q6 `(x,y)` signed i64 values in little-endian order.
- Invalid input returns `-1`; insufficient output capacity returns `-2` without writing; success returns 16 bytes per point.
- Implementations use portable integer arithmetic and no CPU-specific instructions.

The source's seeded Python PRNG is outside this trace-driven contract. Its map selection, affine coefficients, initial origin, and rounded point sequence are retained. The workload includes the four thresholds, the pinned five-point doctest sequence, and a maximum-size trace.

## Build and run

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm barnsley_fern --language rust
python3 benchmarks/run_i64_array_bytes_output.py --build-manifest build/i64_array_bytes_output/b/barnsley_fern/rust/build.json
```

## Implementations

| Language | Source |
|---|---|
| C | [`c/b/barnsley_fern.c`](../../../c/b/barnsley_fern.c) |
| C3 | [`c3/b/barnsley_fern.c3`](../../../c3/b/barnsley_fern.c3) |
| C++ | [`cpp/b/barnsley_fern.cpp`](../../../cpp/b/barnsley_fern.cpp) |
| Elisa | [`elisa/b/barnsley_fern.elisa`](../../../elisa/b/barnsley_fern.elisa) |
| Nim | [`nim/b/barnsley_fern.nim`](../../../nim/b/barnsley_fern.nim) |
| Odin | [`odin/b/barnsley_fern.odin`](../../../odin/b/barnsley_fern.odin) |
| Rust | [`rust/b/barnsley_fern.rs`](../../../rust/b/barnsley_fern.rs) |
| V | [`v/b/barnsley_fern.v`](../../../v/b/barnsley_fern.v) |
| Zig | [`zig/b/barnsley_fern.zig`](../../../zig/b/barnsley_fern.zig) |

## Pinned source

- TheAlgorithms/Python [`barnsley_fern.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/fractals/barnsley_fern.py)
