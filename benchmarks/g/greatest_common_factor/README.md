# Greatest common factor

Fold a nonempty list of nonnegative integers with Euclid's remainder algorithm, following the pinned TypeScript implementation.

## Contract

- The `i64_array_scalar` ABI receives `[count, values...]`, with 1 through 256 values.
- Each value is an integer in `[0, 9,007,199,254,740,991]`, the exact integer range of JavaScript `Number`.
- Return the greatest common factor of the list. A one-element list returns that element; an all-zero list returns zero.
- Invalid counts, packed lengths, negative values, or values above the JavaScript safe-integer limit return `INT64_MIN`, which is outside the valid result range.
- The reduction takes `O(n log M)` time in the bounded domain and constant auxiliary space.

## Source semantics

The pinned [TheAlgorithms TypeScript `greatest_common_factor.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/maths/greatest_common_factor.ts) reduces a list with `binaryGCF`, which rejects negative or non-integer values and repeatedly replaces `(a, b)` with `(b, a % b)`. The benchmark ports the list reduction and gives malformed ABI input a sentinel result. The same source's two-value `binaryGCF` helper is mapped to the existing [`gcd`](../gcd/README.md) benchmark.

## Workload

[`workload.json`](workload.json) covers the upstream examples, single-value and zero cases, a shared factor, coprime values, the safe-integer boundary, the maximum list length, and invalid packed inputs.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/g/greatest_common_factor.c`](../../../c/g/greatest_common_factor.c) |
| C3 | [`c3/g/greatest_common_factor.c3`](../../../c3/g/greatest_common_factor.c3) |
| C++ | [`cpp/g/greatest_common_factor.cpp`](../../../cpp/g/greatest_common_factor.cpp) |
| Elisa | [`elisa/g/greatest_common_factor.elisa`](../../../elisa/g/greatest_common_factor.elisa) |
| Nim | [`nim/g/greatest_common_factor.nim`](../../../nim/g/greatest_common_factor.nim) |
| Odin | [`odin/g/greatest_common_factor.odin`](../../../odin/g/greatest_common_factor.odin) |
| Rust | [`rust/g/greatest_common_factor.rs`](../../../rust/g/greatest_common_factor.rs) |
| V | [`v/g/greatest_common_factor.v`](../../../v/g/greatest_common_factor.v) |
| Zig | [`zig/g/greatest_common_factor.zig`](../../../zig/g/greatest_common_factor.zig) |

The package uses the `i64_array_scalar` benchmark ABI and portable integer arithmetic.
