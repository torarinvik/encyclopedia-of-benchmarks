# Cohen-Sutherland line clipping

This package ports the pinned Java Cohen-Sutherland line clipper for a rectangular window. A selector exposes one coordinate of the returned line, or its acceptance flag, through the shared `i64_array_float64` ABI.

## Contract

- Input is `[component, x_min_micro, y_min_micro, x_max_micro, y_max_micro, x1_micro, y1_micro, x2_micro, y2_micro]`.
- All coordinates are signed integer millionths in `[-1,000,000,000, 1,000,000,000]`, representing real coordinates from -1,000 through 1,000. The window must have `x_min < x_max` and `y_min < y_max`.
- Selectors 0 through 3 return clipped `x1`, `y1`, `x2`, and `y2`; selector 4 returns `1.0` for a non-null clipped line and `0.0` when the source rejects the line. Selecting a coordinate from a rejected line returns the invalid sentinel.
- The implementation preserves the source's region-code and boundary-priority order (top, bottom, right, left). Malformed inputs return `-1e300`; valid coordinates use absolute tolerance `1e-9` and relative tolerance `1e-12`.

## Verification

[`workload.json`](workload.json) covers inside, outside, crossing, vertical, horizontal-boundary, and diagonal segments, each selected coordinate, rejection, and malformed inputs. Run the independent bounded corpus through each available language implementation with:

```sh
python3 benchmarks/verify_cohen_sutherland.py
```

## Pinned source

- Java [`CohenSutherland.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/lineclipping/CohenSutherland.java)

The benchmark covers the pure clipping method. Java's `Point` and `Line` wrappers are represented by the packed coordinate array and selected scalar output.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/cohen_sutherland.c`](../../../c/c/cohen_sutherland.c) |
| C3 | [`c3/c/cohen_sutherland.c3`](../../../c3/c/cohen_sutherland.c3) |
| C++ | [`cpp/c/cohen_sutherland.cpp`](../../../cpp/c/cohen_sutherland.cpp) |
| Elisa | [`elisa/c/cohen_sutherland.elisa`](../../../elisa/c/cohen_sutherland.elisa) |
| Nim | [`nim/c/cohen_sutherland.nim`](../../../nim/c/cohen_sutherland.nim) |
| Odin | [`odin/c/cohen_sutherland.odin`](../../../odin/c/cohen_sutherland.odin) |
| Rust | [`rust/c/cohen_sutherland.rs`](../../../rust/c/cohen_sutherland.rs) |
| V | [`v/c/cohen_sutherland.v`](../../../v/c/cohen_sutherland.v) |
| Zig | [`zig/c/cohen_sutherland.zig`](../../../zig/c/cohen_sutherland.zig) |
