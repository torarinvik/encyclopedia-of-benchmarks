# hsv_to_rgb_conversion

This package ports the HSV-to-RGB direction of the pinned JavaScript conversion module [TheAlgorithms/JavaScript `Conversions/RgbHsvConversion.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/RgbHsvConversion.js). The JavaScript implementation is canonical because source-language ports differ at midpoint rounding.

## Contract

- Input is exactly three signed 64-bit integers `[hue_millidegrees, saturation_scaled, value_scaled]`. Hue is in `0..360000`; saturation and value are in `0..255000000`. Divide hue by 1000 and the other components by 255000000 to obtain the source's binary64 arguments.
- Invalid shape, integer width, or component range returns `-1`. Output-capacity failure returns `-2`.
- Output is three unsigned RGB bytes in R, G, B order; success returns `3`.
- The implementation keeps the pinned source's chroma, second-largest-component, match-value, and inclusive hue-section branches. A hue of 360 degrees uses the final branch and maps to red.
- Each nonnegative channel is rounded as `floor(255 * channel + 0.5)`, matching JavaScript `Math.round` including exact half ties. In particular, HSV `(0°, 0, 128.5/255)` produces `(129,129,129)`.

The independent oracle is [`benchmarks/hsv_to_rgb_conversion_oracle.py`](../../hsv_to_rgb_conversion_oracle.py). The workload includes all six hue boundaries, hue wrap, published examples, invalid values, output-capacity cases, and exact half-byte ties.

Pinned source: [TheAlgorithms/JavaScript `RgbHsvConversion.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/RgbHsvConversion.js).

## Build and record

Build the selected ABI with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm hsv_to_rgb_conversion --language rust

Record the workload with:

    python3 benchmarks/run_i64_array_bytes_output.py --algorithm hsv_to_rgb_conversion

## Implementations

| Language | Source |
| --- | --- |
| C | [c/h/hsv_to_rgb_conversion.c](../../../c/h/hsv_to_rgb_conversion.c) |
| C3 | [c3/h/hsv_to_rgb_conversion.c3](../../../c3/h/hsv_to_rgb_conversion.c3) |
| C++ | [cpp/h/hsv_to_rgb_conversion.cpp](../../../cpp/h/hsv_to_rgb_conversion.cpp) |
| Elisa | [elisa/h/hsv_to_rgb_conversion.elisa](../../../elisa/h/hsv_to_rgb_conversion.elisa) |
| Nim | [nim/h/hsv_to_rgb_conversion.nim](../../../nim/h/hsv_to_rgb_conversion.nim) |
| Odin | [odin/h/hsv_to_rgb_conversion.odin](../../../odin/h/hsv_to_rgb_conversion.odin) |
| Rust | [rust/h/hsv_to_rgb_conversion.rs](../../../rust/h/hsv_to_rgb_conversion.rs) |
| V | [v/h/hsv_to_rgb_conversion.v](../../../v/h/hsv_to_rgb_conversion.v) |
| Zig | [zig/h/hsv_to_rgb_conversion.zig](../../../zig/h/hsv_to_rgb_conversion.zig) |
