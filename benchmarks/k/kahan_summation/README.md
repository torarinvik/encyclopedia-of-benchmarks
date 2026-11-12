# Kahan summation

This package benchmarks ordered Kahan compensated summation over binary64 inputs. It is a distinct algorithm from the repository's formula-specific floating-point sums: every input is consumed in order while a correction term tracks rounding lost by the running total.

## Contract

The `float64_slice_io` input is a sequence of 0 through 256 finite binary64 values. Each value must have absolute magnitude at most `1e100`. An empty sequence produces `0.0`. A null input pointer is invalid, including for a zero-length input. Inputs outside these bounds return `-1`.

For each value `x`, the routine evaluates these operations in this order, using binary64 rounding after each operation:

```text
adjusted = x - correction
next = sum + adjusted
correction = (next - sum) - adjusted
sum = next
```

The initial sum and correction are both `0.0`. Success writes one binary64 output and returns `1`. A null output pointer or capacity below one element returns `-2`, after input validation, and leaves the output untouched. The maximum input length is 256; the output contains one scalar and the recurrence uses two scalar accumulators. The operation count is linear in the input length, with O(1) auxiliary storage.

Kahan summation is order-sensitive and does not guarantee the correctly rounded exact sum for every sequence. The workload includes a pair of half-ULP terms that Kahan recovers and a large-plus-small sequence that returns `2.0` where ordinary left-to-right addition loses both unit terms.

The primary oracle follows the floating-point recurrence in [`../../kahan_summation_oracle.py`](../../kahan_summation_oracle.py). The independent verifier carries out each primitive operation as an exact rational calculation and rounds it back to binary64 before the next operation in [`../../kahan_summation_verifier_oracle.py`](../../kahan_summation_verifier_oracle.py). [`workload.json`](workload.json) records numerical and ABI-boundary cases. The package inventory checker is [`../../check_kahan_summation_package.py`](../../check_kahan_summation_package.py); it is a static source and metadata check.

## Provenance and rights

The algorithm was independently implemented from the high-level Kahan summation description in the [Rosetta Code task](https://rosettagit.org/tasks/kahan-summation/), whose mirror page identifies its content as GFDL 1.3-or-later, and William Kahan's paper, [“Further remarks on reducing truncation errors,” *Communications of the ACM* 8(1), 1965](https://doi.org/10.1145/363707.363723). No upstream implementation, comments, or task prose were copied. See [`RIGHTS.md`](RIGHTS.md) for the source and license record.

## Language ports

| Language | Source |
|---|---|
| C | [`c/k/kahan_summation.c`](../../../c/k/kahan_summation.c) |
| C3 | [`c3/k/kahan_summation.c3`](../../../c3/k/kahan_summation.c3) |
| C++ | [`cpp/k/kahan_summation.cpp`](../../../cpp/k/kahan_summation.cpp) |
| Elisa | [`elisa/k/kahan_summation.elisa`](../../../elisa/k/kahan_summation.elisa) |
| Mojo | [`mojo/k/kahan_summation.mojo`](../../../mojo/k/kahan_summation.mojo) |
| Nim | [`nim/k/kahan_summation.nim`](../../../nim/k/kahan_summation.nim) |
| Odin | [`odin/k/kahan_summation.odin`](../../../odin/k/kahan_summation.odin) |
| Rust | [`rust/k/kahan_summation.rs`](../../../rust/k/kahan_summation.rs) |
| V | [`v/k/kahan_summation.v`](../../../v/k/kahan_summation.v) |
| Zig | [`zig/k/kahan_summation.zig`](../../../zig/k/kahan_summation.zig) |
