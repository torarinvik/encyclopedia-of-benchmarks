# rgb_hsl_conversion

This benchmark implements the pinned JavaScript `rgbToHsl` conversion from [TheAlgorithms/JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Conversions/RgbHslConversion.js).

The source documents an RGB array of integer channels and computes HSL by normalizing channels by 255, selecting the maximum channel, applying its piecewise saturation and hue formulas, wrapping negative hue by 360 degrees, and rounding hue, saturation-percent, and lightness-percent with JavaScript `Math.round`. The maximum-channel tie precedence is green, then blue, then red. Grayscale colors produce hue and saturation zero.

The bounded ABI accepts exactly three signed 64-bit integers `[red, green, blue]`, each in `0..255`. Other lengths or channels return `-1`. The benchmark serializes the source's three integer HSL results as four bytes: hue as unsigned 16-bit little-endian, then saturation and lightness as one byte each. Capacity below four bytes returns `-2`; a successful call returns `4`. Inputs outside the documented integer RGB domain are rejected by the adapter. The JavaScript source mutates its input array while converting; the benchmark compares the observable HSL result and does not expose that in-place mutation.

The workload includes primary colors, grayscale, the source example, channel ties, rounding cases, invalid inputs, and output-capacity boundaries. The oracle is implemented independently in `benchmarks/rgb_hsl_conversion_oracle.py`.
