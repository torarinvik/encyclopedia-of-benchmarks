# Orbital Capture Area

This benchmark ports the capture cross-section function from the pinned Python orbital-capture module.

## Contract

- The `float64_unary` ABI accepts a capture radius in metres in `[0, 1e10]` and returns the circular cross-sectional area in square metres.
- It computes `round(pi * radius², 0)` with nearest-even ties, matching Python's `round(value, 0)`.
- Negative, non-finite, or out-of-range values return `-1e300`. The bounded input keeps the area finite and makes behavior consistent across the nine portable implementations.
- The code uses portable scalar binary64 operations; it does not use CPU-specific instructions.

## Source semantics

The pinned Python `capture_area` multiplies `pi` by the squared capture radius and rounds to a whole square metre. The workload includes the source's documented radius and result. See the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/basic_orbital_capture.py).

## Workload and build

[`workload.json`](workload.json) covers zero, round-to-even boundaries, small and large radii, the source example, and invalid inputs. Build and record with the `float64_unary` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_unary --algorithm orbital_capture_area --language c
python3 benchmarks/run_float64_unary.py --build-manifest build/float64_unary/o/orbital_capture_area/c/build.json
```

Run the cross-language verifier with `python3 benchmarks/verify_orbital_capture.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` when the Elisa compiler is not on `PATH`.

## Implementations

| Language | Source |
|---|---|
| C | [`c/o/orbital_capture_area.c`](../../../c/o/orbital_capture_area.c) |
| C3 | [`c3/o/orbital_capture_area.c3`](../../../c3/o/orbital_capture_area.c3) |
| C++ | [`cpp/o/orbital_capture_area.cpp`](../../../cpp/o/orbital_capture_area.cpp) |
| Elisa | [`elisa/o/orbital_capture_area.elisa`](../../../elisa/o/orbital_capture_area.elisa) |
| Nim | [`nim/o/orbital_capture_area.nim`](../../../nim/o/orbital_capture_area.nim) |
| Odin | [`odin/o/orbital_capture_area.odin`](../../../odin/o/orbital_capture_area.odin) |
| Rust | [`rust/o/orbital_capture_area.rs`](../../../rust/o/orbital_capture_area.rs) |
| V | [`v/o/orbital_capture_area.v`](../../../v/o/orbital_capture_area.v) |
| Zig | [`zig/o/orbital_capture_area.zig`](../../../zig/o/orbital_capture_area.zig) |
