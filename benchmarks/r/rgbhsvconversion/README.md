# RGB and HSV conversion

## Contract

The input array is `[operation, a, b, c]`. Operation `0` converts HSV to RGB using hue in thousandths of a degree (`0..360000`) and saturation/value in thousandths (`0..1000`). It follows the pinned C# six-sector formula and rounds each 8-bit channel with nearest-even rounding; the scalar result is `R<<16 | G<<8 | B`.

Operation `1` converts RGB byte channels (`0..255`) to HSV. It follows the pinned max/min/chroma branches and normalizes hue with `(hue + 360) % 360`. The result packs rounded hue millidegrees, saturation millionths, and value millionths into 20-bit fields: `(hue << 40) | (saturation << 20) | value`. `-1` marks invalid input.

The C ABI entry point is:

```c
int64_t rgbhsvconversion(const int64_t *values, size_t length);
```

## Workload

[`workload.json`](workload.json) covers hue-sector boundaries, gray and black, and invalid operation values. Expected results come from the source-derived [runtime oracle](../../rgbhsvconversion_oracle.py). The benchmark uses `i64_array_scalar` and [`benchmarks/run_i64_array_scalar.py`](../../run_i64_array_scalar.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/rgbhsvconversion.c`](../../../c/r/rgbhsvconversion.c) |
| C3 | [`c3/r/rgbhsvconversion.c3`](../../../c3/r/rgbhsvconversion.c3) |
| C++ | [`cpp/r/rgbhsvconversion.cpp`](../../../cpp/r/rgbhsvconversion.cpp) |
| Elisa | [`elisa/r/rgbhsvconversion.elisa`](../../../elisa/r/rgbhsvconversion.elisa) |
| Nim | [`nim/r/rgbhsvconversion.nim`](../../../nim/r/rgbhsvconversion.nim) |
| Odin | [`odin/r/rgbhsvconversion.odin`](../../../odin/r/rgbhsvconversion.odin) |
| Rust | [`rust/r/rgbhsvconversion.rs`](../../../rust/r/rgbhsvconversion.rs) |
| V | [`v/r/rgbhsvconversion.v`](../../../v/r/rgbhsvconversion.v) |
| Zig | [`zig/r/rgbhsvconversion.zig`](../../../zig/r/rgbhsvconversion.zig) |

## Pinned source

[C# `RGBHSVConversion.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Other/RGBHSVConversion.cs)
