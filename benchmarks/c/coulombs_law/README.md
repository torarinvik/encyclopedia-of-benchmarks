# Coulomb's law

Compute the magnitude of the electrostatic force between two point charges separated by a positive distance.

## Pinned sources

- Java [`CoulombsLaw.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/CoulombsLaw.java) returns a two-dimensional force vector.
- Python [`physics/coulombs_law.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/coulombs_law.py) returns signed force rounded to two decimal places.
- Python [`electronics/coulombs_law.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/coulombs_law.py) solves for one missing value and returns a name/value mapping.

The shared contract selects force calculation. It projects the Java vector to its magnitude, takes the absolute value of the signed Python result, and omits the Python physics source's two-decimal rounding. The electronics source uses the rounded constant `8.988e9`; all ports use `8.9875517923e9`, matching the Java and physics snapshots.

## Contract

The `i64_array_float64` input is `[charge1_microcoulombs, charge2_microcoulombs, distance_millimeters]`. Each signed charge is nonzero and in `[-1,000,000, 1,000,000]` microcoulombs; distance is in `[1, 1,000,000]` millimeters. The array must contain exactly three values. Nonzero charges preserve the electronics source's exactly-one-missing-value rule when force is the requested result.

Convert charges to coulombs and distance to meters, then return the force magnitude in newtons:

`8.9875517923e9 * abs(q1_coulombs * q2_coulombs) / distance_meters^2`

Invalid input returns `-1e300`. The valid bounds keep every output finite.

## Workload and recording

[`workload.json`](workload.json) covers zero and opposite-sign charges, distance scaling, the domain limits, and malformed inputs. The shared float64 runner oracle is maintained by the coordinator.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/c/coulombs_law.c`](../../../c/c/coulombs_law.c) |
| C3 | [`c3/c/coulombs_law.c3`](../../../c3/c/coulombs_law.c3) |
| C++ | [`cpp/c/coulombs_law.cpp`](../../../cpp/c/coulombs_law.cpp) |
| Elisa | [`elisa/c/coulombs_law.elisa`](../../../elisa/c/coulombs_law.elisa) |
| Nim | [`nim/c/coulombs_law.nim`](../../../nim/c/coulombs_law.nim) |
| Odin | [`odin/c/coulombs_law.odin`](../../../odin/c/coulombs_law.odin) |
| Rust | [`rust/c/coulombs_law.rs`](../../../rust/c/coulombs_law.rs) |
| V | [`v/c/coulombs_law.v`](../../../v/c/coulombs_law.v) |
| Zig | [`zig/c/coulombs_law.zig`](../../../zig/c/coulombs_law.zig) |
