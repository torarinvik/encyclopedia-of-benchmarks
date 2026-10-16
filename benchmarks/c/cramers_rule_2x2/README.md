# Cramer's rule for a 2×2 system

Solve the two equations `a1*x + b1*y = c1` and `a2*x + b2*y = c2` with Cramer's rule.

## Contract

- Input is exactly six signed 64-bit integers: `[a1, b1, c1, a2, b2, c2]`. Each coefficient is bounded to `[-1,000,000, 1,000,000]`.
- For a nonsingular system, output the pair `[x, y]` as two IEEE-754 binary64 values in little-endian order. The return value is `2`.
- A singular system returns `-1` and writes no output. This maps the pinned Python source's `ValueError` cases (no solution or infinitely many solutions) to the shared invalid-result code.
- Malformed or out-of-range input returns `-1`; insufficient output capacity returns `-2` without writing output. The output buffer must hold 16 bytes.
- The coefficient bound keeps determinant calculations exact in signed 64-bit arithmetic and every quotient finite. The algorithm takes `O(1)` time and auxiliary space.

## Source

Pinned source: [TheAlgorithms/Python `cramers_rule_2x2.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/matrix/cramers_rule_2x2.py). It computes the determinant and the two replacement determinants, raises for a zero determinant, and otherwise returns `(determinant_x / determinant, determinant_y / determinant)`. The benchmark preserves that calculation and bounds inputs for safe fixed-width ports.

## Workload and implementations

[`workload.json`](workload.json) covers the source examples, positive and negative fractional solutions, a zero solution, singular systems, malformed arrays, coefficient limits, and insufficient capacity. All nine ports use the `i64_array_bytes_output` ABI and encode the solution as a float64 vector with absolute and relative tolerance `1e-12`.

Verify all ports and the workload with:

```sh
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm cramers_rule_2x2
```

| Language | Source |
| --- | --- |
| C | [c/c/cramers_rule_2x2.c](../../../c/c/cramers_rule_2x2.c) |
| C3 | [c3/c/cramers_rule_2x2.c3](../../../c3/c/cramers_rule_2x2.c3) |
| C++ | [cpp/c/cramers_rule_2x2.cpp](../../../cpp/c/cramers_rule_2x2.cpp) |
| Elisa | [elisa/c/cramers_rule_2x2.elisa](../../../elisa/c/cramers_rule_2x2.elisa) |
| Nim | [nim/c/cramers_rule_2x2.nim](../../../nim/c/cramers_rule_2x2.nim) |
| Odin | [odin/c/cramers_rule_2x2.odin](../../../odin/c/cramers_rule_2x2.odin) |
| Rust | [rust/c/cramers_rule_2x2.rs](../../../rust/c/cramers_rule_2x2.rs) |
| V | [v/c/cramers_rule_2x2.v](../../../v/c/cramers_rule_2x2.v) |
| Zig | [zig/c/cramers_rule_2x2.zig](../../../zig/c/cramers_rule_2x2.zig) |
