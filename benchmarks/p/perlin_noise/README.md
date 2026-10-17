# Perlin noise

This benchmark ports only `generatePerlinNoise` from the pinned Java `PerlinNoise` class. It excludes the console demo and its character rendering.

## Contract

- The ABI is `float64_slice_io`. Input is exactly five finite f64 values `[width, height, octave_count, persistence, seed]`. Width and height are exact integers from 1–8, octave count is an exact integer from 1–4, persistence is exactly `0.5`, `0.75`, or `1.0`, and seed is an exact integer from 0 through 2,147,483,647.
- The base grid is filled in `x`-then-`y` order using Java `Random(seed).nextFloat()`. Its 48-bit state starts at `(seed ^ 0x5DEECE66D) & ((1 << 48) - 1)` and advances as `(state * 0x5DEECE66D + 0xB) & ((1 << 48) - 1)`; `nextFloat` uses the top 24 bits divided by `2^24`.
- Each octave samples the base grid with wrapped endpoints and bilinear interpolation. The source interpolation order is `a * (1 - alpha) + alpha * b`. The benchmark preserves binary32 rounding after every Java `float` operation, including interpolation, the descending octave blend, amplitude and total-amplitude updates, accumulation, and normalization. Output values are widened from the resulting `float` cells to f64 and flattened in source `[x][y]` order. Comparisons use zero absolute and relative tolerance because the f64 outputs are exact widenings of binary32 results.
- Invalid, malformed, or null input returns `-1` before output-buffer checks. Valid input with a null output or insufficient capacity returns `-2` without writes. The output contains `width * height` values, up to 64 elements; success returns that element count.

The workload covers Java RNG seeds, x-major ordering, wrapped interpolation for narrow grids, octave counts, each allowed persistence, maximum dimensions, exact source rounding, and invalid parameters. See [workload.json](workload.json) and the independent [oracle](../../perlin_noise_oracle.py).

Pinned source: [TheAlgorithms/Java `PerlinNoise.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/PerlinNoise.java), method `generatePerlinNoise`, at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`.

## Reproduce

~~~
python3 benchmarks/build_abi.py --family float64_slice_io --algorithm perlin_noise --language rust
python3 benchmarks/run_float64_slice_io.py --build-manifest build/float64_slice_io/p/perlin_noise/rust/build.json
python3 benchmarks/verify_float64_slice_io.py --algorithm perlin_noise --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/p/perlin_noise.c](../../../c/p/perlin_noise.c) |
| C3 | [c3/p/perlin_noise.c3](../../../c3/p/perlin_noise.c3) |
| C++ | [cpp/p/perlin_noise.cpp](../../../cpp/p/perlin_noise.cpp) |
| Elisa | [elisa/p/perlin_noise.elisa](../../../elisa/p/perlin_noise.elisa) |
| Nim | [nim/p/perlin_noise.nim](../../../nim/p/perlin_noise.nim) |
| Odin | [odin/p/perlin_noise.odin](../../../odin/p/perlin_noise.odin) |
| Rust | [rust/p/perlin_noise.rs](../../../rust/p/perlin_noise.rs) |
| V | [v/p/perlin_noise.v](../../../v/p/perlin_noise.v) |
| Zig | [zig/p/perlin_noise.zig](../../../zig/p/perlin_noise.zig) |
