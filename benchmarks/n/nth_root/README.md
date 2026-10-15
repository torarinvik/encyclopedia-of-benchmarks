# Nth Root by Newton's Method

This benchmark follows the pinned Python implementation of Newton's method for a real nth root. It returns the approximation produced by the source's iteration and stopping rule.

## Contract

- The `float64_triple` ABI supplies `[radicand, index, tolerance]`. The radicand must be finite and in `[0.5, 1000]`; `index` must be an exactly represented integer in `[3, 8]`; tolerance must be finite and in `[1e-12, 1e-3]`.
- Preserve the source initialization `new = radicand`, `old = new + tolerance + 0.1`, and continue while `tolerance <= abs(old - new)`. Each iteration assigns `old = new`, then evaluates `(index - 1) / index * old`, followed by `radicand / (index * old^(index - 1))`, and adds the terms in that order.
- Return the final binary64 approximation. Inputs outside the contract return `-1e300`. Valid results are compared with relative and absolute tolerance `1e-12`.

The source also accepts index 1, returns zero for a zero radicand, and supports negative radicands for odd indices. This benchmark fixes indices to 3 through 8 and positive radicands. The lower index bound keeps this general root iteration distinct from the square-root benchmarks; the positive bound avoids source-specific negative-root behavior.

## Source

- [TheAlgorithms/Python `nth_root.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/numerical_analysis/nth_root.py)

## Workload and build

[`workload.json`](workload.json) covers exact roots, non-perfect roots, the range edges, and varied tolerances. Build with the `float64_triple` ABI and record with `benchmarks/run_float64_triple.py`.

```sh
python3 benchmarks/build_abi.py --family float64_triple --algorithm nth_root --language rust
python3 benchmarks/run_float64_triple.py --build-manifest build/float64_triple/n/nth_root/rust/build.json
```

## Ports

| Language | Source |
| --- | --- |
| C | [`c/n/nth_root.c`](../../../c/n/nth_root.c) |
| C3 | [`c3/n/nth_root.c3`](../../../c3/n/nth_root.c3) |
| C++ | [`cpp/n/nth_root.cpp`](../../../cpp/n/nth_root.cpp) |
| Elisa | [`elisa/n/nth_root.elisa`](../../../elisa/n/nth_root.elisa) |
| Nim | [`nim/n/nth_root.nim`](../../../nim/n/nth_root.nim) |
| Odin | [`odin/n/nth_root.odin`](../../../odin/n/nth_root.odin) |
| Rust | [`rust/n/nth_root.rs`](../../../rust/n/nth_root.rs) |
| V | [`v/n/nth_root.v`](../../../v/n/nth_root.v) |
| Zig | [`zig/n/nth_root.zig`](../../../zig/n/nth_root.zig) |
