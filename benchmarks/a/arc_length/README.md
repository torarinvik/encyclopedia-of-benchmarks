# Arc length

## Contract

Input is `[radius, angle, unit]`, all binary64 values. Radius is in `[0, 1,000,000]`. When `unit` is `0`, angle is in degrees from 0 through 360 and arc length is `2πr(angle / 360)`. When `unit` is `1`, angle is in radians from 0 through `2π` and arc length is `r × angle`.

The Nim source provides degree and radian functions, while the Python source provides degrees only. The benchmark combines the two units behind one mode parameter; degree cases preserve the Python behavior. No existing benchmark covers circular arc length: the shape-area benchmark covers area and surface-area formulas.

## Workload and reproduction

The workload includes the published degree examples, zero angle and radius, a full circle, radian examples, and the maximum bounded radius. The `float64_triple` family passes radius, angle, and the unit selector as three binary64 inputs.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm arc_length --language rust --with-checker
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/a/arc_length/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/arc_length.c`](../../../c/a/arc_length.c) |
| C3 | [`c3/a/arc_length.c3`](../../../c3/a/arc_length.c3) |
| C++ | [`cpp/a/arc_length.cpp`](../../../cpp/a/arc_length.cpp) |
| Elisa | [`elisa/a/arc_length.elisa`](../../../elisa/a/arc_length.elisa) |
| Nim | [`nim/a/arc_length.nim`](../../../nim/a/arc_length.nim) |
| Odin | [`odin/a/arc_length.odin`](../../../odin/a/arc_length.odin) |
| Rust | [`rust/a/arc_length.rs`](../../../rust/a/arc_length.rs) |
| V | [`v/a/arc_length.v`](../../../v/a/arc_length.v) |
| Zig | [`zig/a/arc_length.zig`](../../../zig/a/arc_length.zig) |

## TheAlgorithms references

- [Nim `arc_length.nim`](https://github.com/TheAlgorithms/Nim/blob/63eec16614b46c91078653e8d3c049fe99ad36b3/maths/arc_length.nim)
- [Python `arc_length.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/arc_length.py)
