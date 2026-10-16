# Color contrast ratio

Compute the contrast ratio between two opaque sRGB colors, represented by their 8-bit red, green, and blue channels.

## Contract

- The i64_array_float64 ABI receives exactly six signed integers in this order: `[red_1, green_1, blue_1, red_2, green_2, blue_2]`.
- Each channel must be in `[0, 255]`, matching construction of two valid Java `Color(red, green, blue)` values. Malformed arrays and out-of-range channels return `-1e300` under the benchmark ABI.
- Decode each channel as `channel / 255.0`. Preserve the pinned source's transfer threshold `0.03928`: values at or below it are divided by `12.92`; larger values are transformed with `((sRGB + 0.055) / 1.055) ** 2.4`.
- Relative luminance is accumulated in source order as `0.2126 * red + 0.7152 * green + 0.0722 * blue`. The result is `(lighter_luminance + 0.05) / (darker_luminance + 0.05)`; identical colors return `1.0` and black against white returns `21.0`.
- Results are compared with relative and absolute tolerance `1e-12`.

## Source

This follows the pinned [TheAlgorithms/Java ColorContrastRatio.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/ColorContrastRatio.java). It implements the WCAG relative-luminance procedure with the source's explicit constants and operation order.

## Workload and build

The workload covers black/white in both argument orders, identical colors, primaries, mixed channels, transfer-branch values, and malformed or out-of-range inputs. The source-backed expected-value check belongs in the shared i64_array_float64 runner.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm color_contrast_ratio --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/c/color_contrast_ratio/rust/build.json
```

Verify all nine ports against the independent luminance oracle with:

```sh
python3 benchmarks/verify_color_contrast_ratio.py
```

## Ports

| Language | Source |
| --- | --- |
| C | [c/c/color_contrast_ratio.c](../../../c/c/color_contrast_ratio.c) |
| C3 | [c3/c/color_contrast_ratio.c3](../../../c3/c/color_contrast_ratio.c3) |
| C++ | [cpp/c/color_contrast_ratio.cpp](../../../cpp/c/color_contrast_ratio.cpp) |
| Elisa | [elisa/c/color_contrast_ratio.elisa](../../../elisa/c/color_contrast_ratio.elisa) |
| Nim | [nim/c/color_contrast_ratio.nim](../../../nim/c/color_contrast_ratio.nim) |
| Odin | [odin/c/color_contrast_ratio.odin](../../../odin/c/color_contrast_ratio.odin) |
| Rust | [rust/c/color_contrast_ratio.rs](../../../rust/c/color_contrast_ratio.rs) |
| V | [v/c/color_contrast_ratio.v](../../../v/c/color_contrast_ratio.v) |
| Zig | [zig/c/color_contrast_ratio.zig](../../../zig/c/color_contrast_ratio.zig) |
