# Heron's formula

Calculate triangle area from its three side lengths using the pinned Java implementation of Heron's formula.

## Contract

- The float64_triple ABI accepts [a, b, c] as binary64 values. Each side must be an integer-valued number in 1..1,000,000.
- All three triangle inequalities are strict. Valid inputs return sqrt(s * (s - a) * (s - b) * (s - c)), where s = (a + b + c) / 2.
- Invalid, fractional, nonpositive, out-of-range, or non-triangle inputs return -1.0. The source throws an IllegalArgumentException for nonpositive sides or invalid triangles; this benchmark maps those cases to the sentinel.
- Integer-valued sides keep the input and semiperimeter exact in binary64. The bound keeps every product and result finite.
- The calculation takes O(1) time and O(1) auxiliary space.

## Source

This follows the pinned [TheAlgorithms Java HeronsFormula.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/HeronsFormula.java). The source validates positive side lengths and strict triangle inequalities, computes the semiperimeter, then evaluates the four-factor product in the same order before taking its square root.

The source accepts positive doubles. This benchmark uses bounded integer-valued sides so the shared float64 contract has a precise common domain and avoids rounding a nearly degenerate side sum across a validation boundary.

## Workload and build

[workload.json](workload.json) covers integer and irrational areas, a valid near-degenerate triangle, the maximum side bound, and invalid side/domain cases. The shared float64_triple oracle branch is pending.

Build and record with the float64_triple ABI:

    python3 benchmarks/build_abi.py --family float64_triple --algorithm herons_formula --language rust
    python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/h/herons_formula/rust/build.json

## Implementations

| Language | Source |
| --- | --- |
| C | [c/h/herons_formula.c](../../../c/h/herons_formula.c) |
| C3 | [c3/h/herons_formula.c3](../../../c3/h/herons_formula.c3) |
| C++ | [cpp/h/herons_formula.cpp](../../../cpp/h/herons_formula.cpp) |
| Elisa | [elisa/h/herons_formula.elisa](../../../elisa/h/herons_formula.elisa) |
| Nim | [nim/h/herons_formula.nim](../../../nim/h/herons_formula.nim) |
| Odin | [odin/h/herons_formula.odin](../../../odin/h/herons_formula.odin) |
| Rust | [rust/h/herons_formula.rs](../../../rust/h/herons_formula.rs) |
| V | [v/h/herons_formula.v](../../../v/h/herons_formula.v) |
| Zig | [zig/h/herons_formula.zig](../../../zig/h/herons_formula.zig) |

