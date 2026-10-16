# Orbital Capture Radii

This benchmark ports the capture-radius calculation from the pinned Python orbital-capture module.

## Contract

- The `float64_triple` ABI receives `[target_radius_m, target_mass_kg, projectile_velocity_m_s]` and returns the capture radius in metres.
- The bounded benchmark domain is radius `[1e-6, 1e10]` metres, mass `[0, 2e30]` kilograms, and speed `[1e6, 299792458]` metres per second. This avoids the source's zero-radius and zero-speed divisions and keeps every result finite.
- The calculation uses `G = 6.67430e-11` and follows `R * sqrt(1 + ((2 * G * M) / R) / v²)`. It rounds to a whole metre using nearest-even ties, as Python's `round(value, 0)` does.
- Invalid inputs return `-1e300`. The benchmark uses portable scalar binary64 math and does not rely on CPU-specific instructions.

## Source semantics

The pinned Python module defines both `capture_radii` and `capture_area`. This benchmark preserves the radius formula and the documented solar example, while supplying deterministic bounds for valid cross-language inputs. Its `G` and speed-of-light values match the constants used by the source. See the pinned [Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/basic_orbital_capture.py).

## Workload and build

[`workload.json`](workload.json) covers the source example, zero-mass round-to-even ties, Earth-like and high-focusing cases, parameter bounds, and invalid inputs. Build and record with the `float64_triple` ABI:

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm orbital_capture_radii --language c
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/o/orbital_capture_radii/c/build.json
```

Run the cross-language verifier with `python3 benchmarks/verify_orbital_capture.py --elisa-compiler ../Elisa-compiler/bin/elisac-stage1` when the Elisa compiler is not on `PATH`.

## Implementations

| Language | Source |
|---|---|
| C | [`c/o/orbital_capture_radii.c`](../../../c/o/orbital_capture_radii.c) |
| C3 | [`c3/o/orbital_capture_radii.c3`](../../../c3/o/orbital_capture_radii.c3) |
| C++ | [`cpp/o/orbital_capture_radii.cpp`](../../../cpp/o/orbital_capture_radii.cpp) |
| Elisa | [`elisa/o/orbital_capture_radii.elisa`](../../../elisa/o/orbital_capture_radii.elisa) |
| Nim | [`nim/o/orbital_capture_radii.nim`](../../../nim/o/orbital_capture_radii.nim) |
| Odin | [`odin/o/orbital_capture_radii.odin`](../../../odin/o/orbital_capture_radii.odin) |
| Rust | [`rust/o/orbital_capture_radii.rs`](../../../rust/o/orbital_capture_radii.rs) |
| V | [`v/o/orbital_capture_radii.v`](../../../v/o/orbital_capture_radii.v) |
| Zig | [`zig/o/orbital_capture_radii.zig`](../../../zig/o/orbital_capture_radii.zig) |
