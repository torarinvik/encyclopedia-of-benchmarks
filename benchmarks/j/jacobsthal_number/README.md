# Jacobsthal number

The pinned Java implementation computes the Jacobsthal sequence iteratively with signed `long` values. It returns `0` for index 0 and `1` for index 1, then applies `J(n) = J(n-1) + 2*J(n-2)`.

## Contract

- Input is a signed 64-bit integer index in `0..=64`.
- Return the exact Jacobsthal number `J(n)` as a signed 64-bit integer.
- Return `-1` for negative indices and indices above 64.
- `J(64) = 6,148,914,691,236,517,205` fits signed 64-bit. `J(65)` exceeds `INT64_MAX`; the Java source's `long` recurrence would overflow at that index, while this benchmark maps it to `-1`.

The input bound includes both source base cases and keeps every recurrence result representable. All ports use the same iterative recurrence and do not compute an unused next term.

## Workload

[`workload.json`](workload.json) covers negative and out-of-range sentinels, both initial terms, representative recurrence values, the largest supported index, and the first overflowing index.

The scalar ABI is `int64_t jacobsthal_number(int64_t n)`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/j/jacobsthal_number.c`](../../../c/j/jacobsthal_number.c) |
| C3 | [`c3/j/jacobsthal_number.c3`](../../../c3/j/jacobsthal_number.c3) |
| C++ | [`cpp/j/jacobsthal_number.cpp`](../../../cpp/j/jacobsthal_number.cpp) |
| Elisa | [`elisa/j/jacobsthal_number.elisa`](../../../elisa/j/jacobsthal_number.elisa) |
| Nim | [`nim/j/jacobsthal_number.nim`](../../../nim/j/jacobsthal_number.nim) |
| Odin | [`odin/j/jacobsthal_number.odin`](../../../odin/j/jacobsthal_number.odin) |
| Rust | [`rust/j/jacobsthal_number.rs`](../../../rust/j/jacobsthal_number.rs) |
| V | [`v/j/jacobsthal_number.v`](../../../v/j/jacobsthal_number.v) |
| Zig | [`zig/j/jacobsthal_number.zig`](../../../zig/j/jacobsthal_number.zig) |

## Upstream source

- [TheAlgorithms/Java `JacobsthalNumber.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/JacobsthalNumber.java)
