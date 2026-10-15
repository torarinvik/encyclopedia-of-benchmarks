# Centripetal Force

Ports the formula from the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/centripetal_force.py): `F = (mass * velocity**2) / radius`.

The `i64_array_float64` ABI takes exactly three signed integer values in the order `[mass, velocity, radius]`. Mass is in 0..1,000, velocity in -1,000..1,000, and radius in 1..1,000. The output is binary64. The Python source accepts floating-point parameters, but this benchmark intentionally covers only an integral subset; its fractional-mass doctest cases (15.5 and 12.25) are not represented. Mass zero is valid, velocity may be negative, and the source rejects negative mass or nonpositive radius. Invalid length or values return -1e300.

The bounds keep the largest pre-division product at 1,000,000,000, exactly representable in binary64 and safely within signed 64-bit range. The implementations preserve the source multiplication and division order. Runtime and auxiliary space are O(1).

## Workload and build

[`workload.json`](workload.json) covers negative velocity, zero mass and velocity, a fractional result, invalid packed input, and out-of-domain values.

```sh
python3 benchmarks/build_abi.py --family i64_array_float64 --algorithm centripetal_force --language rust
python3 benchmarks/run_i64_array_float64.py --build-manifest build/i64_array_float64/c/centripetal_force/rust/build.json
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/centripetal_force.c`](../../../c/c/centripetal_force.c) |
| C3 | [`c3/c/centripetal_force.c3`](../../../c3/c/centripetal_force.c3) |
| C++ | [`cpp/c/centripetal_force.cpp`](../../../cpp/c/centripetal_force.cpp) |
| Elisa | [`elisa/c/centripetal_force.elisa`](../../../elisa/c/centripetal_force.elisa) |
| Nim | [`nim/c/centripetal_force.nim`](../../../nim/c/centripetal_force.nim) |
| Odin | [`odin/c/centripetal_force.odin`](../../../odin/c/centripetal_force.odin) |
| Rust | [`rust/c/centripetal_force.rs`](../../../rust/c/centripetal_force.rs) |
| V | [`v/c/centripetal_force.v`](../../../v/c/centripetal_force.v) |
| Zig | [`zig/c/centripetal_force.zig`](../../../zig/c/centripetal_force.zig) |
