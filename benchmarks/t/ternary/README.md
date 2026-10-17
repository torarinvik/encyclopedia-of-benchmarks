# Ternary search for a maximum or minimum

This package ports the pinned recursive ternary search routines for fixed unimodal objectives.

## Contract

Input is exactly `[operation, a_milli, b_milli, epsilon_micro, max_calls]`; one extra value is admitted by the parser for malformed-input coverage. Operation `0` searches for the maximum of `-(x-1)^2`; operation `1` searches for the minimum of `(x+1)^2`. Endpoint fields are divided by 1,000 and must lie in [-1,000, 1,000], with `a <= b`. Epsilon is divided by 1,000,000 and must be in [0.000001, 1]. The recursive frame budget is from 1 through 64, counting the initial call as frame 1.

Each frame checks `abs(a-b) <= epsilon` first and, when true, returns the objective at `(a+b)/2`. Otherwise it computes left then right trisection points, evaluates the objective at each in source order, and recurses with the source's strict comparison; ties take the `a, right` branch. If the next recursive frame would exceed the budget, the call returns `-1e300`. Invalid inputs use the same sentinel. Output comparisons use absolute and relative tolerances of `1e-12`.

Pinned source: [ternary.go](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/search/ternary.go). See [workload](workload.json) and [oracle](../../ternary_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/t/ternary.c |
| C3 | ../../../c3/t/ternary.c3 |
| C++ | ../../../cpp/t/ternary.cpp |
| Elisa | ../../../elisa/t/ternary.elisa |
| Nim | ../../../nim/t/ternary.nim |
| Odin | ../../../odin/t/ternary.odin |
| Rust | ../../../rust/t/ternary.rs |
| V | ../../../v/t/ternary.v |
| Zig | ../../../zig/t/ternary.zig |
