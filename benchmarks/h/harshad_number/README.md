# Harshad Number

Check whether a positive base-10 integer is divisible by the sum of its decimal digits. Return `1` for a Harshad number and `0` otherwise.

## Contract

- Input is one signed 64-bit integer in the bounded domain `1` through `2,147,483,647`.
- Valid inputs return `1` when `n % digit_sum(n) == 0`, and `0` otherwise.
- Inputs outside the positive signed 32-bit range return `-1`. The pinned Java method throws for nonpositive values; the shared ABI represents those and values above the benchmark bound with the invalid-result sentinel.
- The benchmark measures the integer `isHarshad(long)` source overload. It is distinct from the catalog's `harshad_numbers` candidate, which enumerates Harshad values.

## Workload and measurement

[`workload.json`](workload.json) covers single-digit, divisible, nondivisible, source-example, upper-bound, and invalid inputs. The scalar runner times repeated calls for each fixed input.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/h/harshad_number.c`](../../../c/h/harshad_number.c) |
| C3 | [`c3/h/harshad_number.c3`](../../../c3/h/harshad_number.c3) |
| C++ | [`cpp/h/harshad_number.cpp`](../../../cpp/h/harshad_number.cpp) |
| Elisa | [`elisa/h/harshad_number.elisa`](../../../elisa/h/harshad_number.elisa) |
| Nim | [`nim/h/harshad_number.nim`](../../../nim/h/harshad_number.nim) |
| Odin | [`odin/h/harshad_number.odin`](../../../odin/h/harshad_number.odin) |
| Rust | [`rust/h/harshad_number.rs`](../../../rust/h/harshad_number.rs) |
| V | [`v/h/harshad_number.v`](../../../v/h/harshad_number.v) |
| Zig | [`zig/h/harshad_number.zig`](../../../zig/h/harshad_number.zig) |

## Source

The pinned [TheAlgorithms/Java implementation](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/HarshadNumber.java) exposes `isHarshad(long)`, which sums decimal digits by repeated division and checks divisibility. The ports preserve that integer operation under the bounded scalar ABI.
