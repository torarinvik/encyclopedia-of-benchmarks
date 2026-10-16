# rgb_hsv_conversion

This package implements the `rgbToHsv` direction of the pinned JavaScript conversion module [TheAlgorithms/JavaScript `Conversions/RgbHsvConversion.js`](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/RgbHsvConversion.js). Its integer RGB to HSV formula also matches the pinned Java, Python, Rust, and C# implementations on this input domain. The C# `RGBHSVConversion` source is an alias for this behavior.

## Contract

- Input is exactly three signed 64-bit integers `[red, green, blue]`, each in `0..255`. Invalid shape or channel values return `-1`.
- Output is the source's `[hue, saturation, value]` tuple as three IEEE-754 binary64 values in little-endian byte order (24 bytes total). Hue is in degrees; saturation and value are in `0..1`. Output capacity below 24 bytes returns `-2`; success returns `24`.
- The algorithm normalizes channels by 255, selects the maximum value with red-then-green tie precedence, computes chroma and saturation, chooses the hue formula by that same maximum precedence, then applies `(hue + 360) % 360`. It does not quantize the resulting floats.
- The source module also exposes HSV-to-RGB. That reverse direction is outside this package: the source set has different midpoint-rounding behavior there (Python/C# versus JavaScript/Java/Rust), while RGB-to-HSV agrees for integer channels.

The independent oracle is [`benchmarks/rgb_hsv_conversion_oracle.py`](../../rgb_hsv_conversion_oracle.py). It serializes binary64 outputs directly so the workload checks the full tuple rather than a lossy checksum.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rgb_hsv_conversion.c`](../../../c/rgb_hsv_conversion.c) |
| C3 | [`c3/r/rgb_hsv_conversion.c3`](../../../c3/r/rgb_hsv_conversion.c3) |
| C++ | [`cpp/r/rgb_hsv_conversion.cpp`](../../../cpp/r/rgb_hsv_conversion.cpp) |
| Elisa | [`elisa/r/rgb_hsv_conversion.elisa`](../../../elisa/r/rgb_hsv_conversion.elisa) |
| Nim | [`nim/r/rgb_hsv_conversion.nim`](../../../nim/r/rgb_hsv_conversion.nim) |
| Odin | [`odin/r/rgb_hsv_conversion.odin`](../../../odin/r/rgb_hsv_conversion.odin) |
| Rust | [`rust/r/rgb_hsv_conversion.rs`](../../../rust/r/rgb_hsv_conversion.rs) |
| V | [`v/r/rgb_hsv_conversion.v`](../../../v/r/rgb_hsv_conversion.v) |
| Zig | [`zig/r/rgb_hsv_conversion.zig`](../../../zig/r/rgb_hsv_conversion.zig) |
