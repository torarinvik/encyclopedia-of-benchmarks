# Sparsity

Compute the proportion of zero entries in a matrix using the pinned Java implementation's exact `value == 0.0` rule.

## Contract

- The `i64_array_float64` ABI accepts `[rows, columns, row-major entries...]` with exactly `2 + rows * columns` signed 64-bit integers.
- Rows and columns are each in `1..63`. Entries are integer-valued matrix elements in `[-1,000,000, 1,000,000]`; these values convert exactly to Java binary64. The maximum input has 3,969 entries and 3,971 packed values.
- This rectangular, finite integer-valued domain is a bounded subset of the source's `double[][]` input. Invalid dimensions, length, or entries return `-1e300`.
- The result is `zero_count / (rows * columns)` as binary64, compared with absolute tolerance `1e-15` and relative tolerance `1e-12`.

## Source semantics

The package follows [`Sparsity.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/misc/Sparsity.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. The source rejects a null matrix, zero rows, and an empty first row; it then counts values equal to `0.0` across all rows and divides by the total number of visited elements. This ABI fixes a nonempty rectangular shape and bounds the count to avoid Java `int` overflow.

See the [workload](workload.json) and [oracle](../../sparsity_oracle.py).

## Implementations

| Language | Port |
|---|---|
| C | [sparsity.c](../../../c/s/sparsity.c) |
| C3 | [sparsity.c3](../../../c3/s/sparsity.c3) |
| C++ | [sparsity.cpp](../../../cpp/s/sparsity.cpp) |
| Elisa | [sparsity.elisa](../../../elisa/s/sparsity.elisa) |
| Nim | [sparsity.nim](../../../nim/s/sparsity.nim) |
| Odin | [sparsity.odin](../../../odin/s/sparsity.odin) |
| Rust | [sparsity.rs](../../../rust/s/sparsity.rs) |
| V | [sparsity.v](../../../v/s/sparsity.v) |
| Zig | [sparsity.zig](../../../zig/s/sparsity.zig) |
