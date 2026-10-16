# Trinomial triangle coefficient

## Contract

Given signed integers `[n, k]`, return the coefficient at row `n`, position `k` in the trinomial triangle. The shared domain is `0 <= n <= 10` and `-10 <= k <= 10`; inputs outside it return `-1`.

The pinned Java routine returns `1` at `(0, 0)`, returns `0` when `k < -n` or `k > n`, and otherwise recursively evaluates the three children in order:

`T(n - 1, k - 1) + T(n - 1, k) + T(n - 1, k + 1)`

The ports preserve the direct, non-memoized recursion and this addition order. The bound keeps recursion practical and every value within signed 32-bit range. The exported ABI is `int64_t trinomial_triangle(int64_t n, int64_t k)` using `binary_scalar`.

## Source review and distinction

The benchmark measures the Java `trinomialValue` coefficient query. It does not time `printTrinomial`, which formats multiple rows. Trinomial coefficients use three recursive predecessors and differ from the two-parent Pascal/binomial coefficients and from packages that generate a complete triangle.

The pinned Java method has no negative-row guard; negative `n` is excluded from the benchmark contract because it can recurse without reaching its base case. For nonnegative rows, positions outside the row return zero as in the source. Positions outside the shared bounded ABI domain return `-1`.

## Workload and recording

[`workload.json`](workload.json) includes the base row, edge positions, center coefficients, and source zero results for positions beyond a row. The verifier checks every position in the bounded `(n, k)` domain against an independently generated iterative row.

```sh
python3 benchmarks/build_abi.py --family binary_scalar --algorithm trinomial_triangle --language rust
python3 benchmarks/run_binary_scalar.py --build-manifest build/binary_scalar/t/trinomial_triangle/rust/build.json
python3 benchmarks/verify_binary_scalar.py --algorithms trinomial_triangle --languages rust
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/t/trinomial_triangle.c`](../../../c/t/trinomial_triangle.c) |
| C3 | [`c3/t/trinomial_triangle.c3`](../../../c3/t/trinomial_triangle.c3) |
| C++ | [`cpp/t/trinomial_triangle.cpp`](../../../cpp/t/trinomial_triangle.cpp) |
| Elisa | [`elisa/t/trinomial_triangle.elisa`](../../../elisa/t/trinomial_triangle.elisa) |
| Nim | [`nim/t/trinomial_triangle.nim`](../../../nim/t/trinomial_triangle.nim) |
| Odin | [`odin/t/trinomial_triangle.odin`](../../../odin/t/trinomial_triangle.odin) |
| Rust | [`rust/t/trinomial_triangle.rs`](../../../rust/t/trinomial_triangle.rs) |
| V | [`v/t/trinomial_triangle.v`](../../../v/t/trinomial_triangle.v) |
| Zig | [`zig/t/trinomial_triangle.zig`](../../../zig/t/trinomial_triangle.zig) |

## TheAlgorithms reference

- Java [`TrinomialTriangle.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/TrinomialTriangle.java)
