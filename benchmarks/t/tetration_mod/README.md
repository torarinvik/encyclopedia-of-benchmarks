# Tetration Modulo an Integer

Compute the height-`B` power tower with base `A` modulo `M`. The tower convention is `T(A,0)=1` and `T(A,h)=A^T(A,h-1)`; in particular, this task defines `0^0` as `1`.

## Contract

The `i64_array_scalar` ABI accepts exactly `[A, B, M]`. Valid inputs have `0 <= A,B <= 1,000,000,000` and `1 <= M <= 1,000,000,000`; invalid inputs return `-1`. Each call represents one case from the [Library Checker Tetration Mod task](https://judge.yosupo.jp/problem/tetration_mod), whose input batches up to 1,000 cases.

For `M > 1`, each recursive level evaluates the previous tower modulo `φ(M)`. If that tower is at least `φ(M)`, the evaluator adds `φ(M)` to its residue before modular exponentiation; this supplies a valid exponent for both coprime and non-coprime bases. A capped tower calculation determines whether the exponent is large without constructing it. The recursion follows the shrinking totient chain, while each totient uses bounded trial division.

## Relationship to the Project Euler 188 benchmark

The repository's [`problem188`](../../p/problem188/README.md) benchmark shares the tetration theme, but uses a pinned recurrence for moduli of the form `10^digits` and preserves that source's unmodded height-one result. This package implements the general bounded modulus contract, including non-coprime bases, height zero, and the `0^0 = 1` convention, with totient lifting and capped tower detection.

See [`workload.json`](workload.json) for height, base, modulus, and boundary cases, and [`benchmarks/tetration_mod_oracle.py`](../../tetration_mod_oracle.py) for a Python arbitrary-precision reference implementation.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/tetration_mod.c`](../../../c/t/tetration_mod.c) |
| C3 | [`c3/t/tetration_mod.c3`](../../../c3/t/tetration_mod.c3) |
| C++ | [`cpp/t/tetration_mod.cpp`](../../../cpp/t/tetration_mod.cpp) |
| Elisa | [`elisa/t/tetration_mod.elisa`](../../../elisa/t/tetration_mod.elisa) |
| Mojo | [`mojo/t/tetration_mod.mojo`](../../../mojo/t/tetration_mod.mojo) |
| Nim | [`nim/t/tetration_mod.nim`](../../../nim/t/tetration_mod.nim) |
| Odin | [`odin/t/tetration_mod.odin`](../../../odin/t/tetration_mod.odin) |
| Rust | [`rust/t/tetration_mod.rs`](../../../rust/t/tetration_mod.rs) |
| V | [`v/t/tetration_mod.v`](../../../v/t/tetration_mod.v) |
| Zig | [`zig/t/tetration_mod.zig`](../../../zig/t/tetration_mod.zig) |
