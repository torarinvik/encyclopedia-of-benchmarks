# Boyle's Law

This package benchmarks the pinned [TheAlgorithms/Python implementation](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/physics/boyles_law.py). Given three of `v1`, `v2`, `p1`, and `p2`, the source solves the omitted variable from `p1 * v1 = p2 * v2`. Every supplied value must be positive. The source formats its result to three decimal places before returning it.

The `i64_array_float64` ABI accepts exactly four signed integers: `[missing_variable_index, value_a, value_b, value_c]`. Indices 0, 1, 2, and 3 mean missing `v1`, `v2`, `p1`, and `p2`, respectively. Pack the remaining three values in the canonical order `[v1, v2, p1, p2]`, skipping the missing slot. For example, index 3 with values `[100,120,150]` represents `v1=100`, `v2=120`, `p1=150` and solves for `p2`.

Each supplied value is bounded to 1..1,000. These bounds preserve the source's positive-value guard and keep integer products and the scaled rounding numerator within signed 64-bit range. After computing the quotient, the benchmark applies a normalized exact-rational rounding rule: round to three decimal places using ties-to-even. The nine ports use this same rule. The pinned Python source instead formats the binary64 quotient with `.3f` and parses that string back; for `[3, 1, 80, 1]`, that source formatting yields `0.013`, while this benchmark's exact-rational tie rule yields `0.012`. Invalid length, index, or supplied values return -1e300. The ABI returns only the numeric result; the source's result key and unit suffix are implied by the missing-variable index.

Runtime and auxiliary space are O(1).

## Verification

Run the independent bounded corpus through each available language implementation with:

```sh
python3 benchmarks/verify_boyles_law.py
```

## Implementations

| Language | Source |
| --- | --- |
| C | [c/b/boyles_law.c](../../../c/b/boyles_law.c) |
| C3 | [c3/b/boyles_law.c3](../../../c3/b/boyles_law.c3) |
| C++ | [cpp/b/boyles_law.cpp](../../../cpp/b/boyles_law.cpp) |
| Elisa | [elisa/b/boyles_law.elisa](../../../elisa/b/boyles_law.elisa) |
| Nim | [nim/b/boyles_law.nim](../../../nim/b/boyles_law.nim) |
| Odin | [odin/b/boyles_law.odin](../../../odin/b/boyles_law.odin) |
| Rust | [rust/b/boyles_law.rs](../../../rust/b/boyles_law.rs) |
| V | [v/b/boyles_law.v](../../../v/b/boyles_law.v) |
| Zig | [zig/b/boyles_law.zig](../../../zig/b/boyles_law.zig) |
