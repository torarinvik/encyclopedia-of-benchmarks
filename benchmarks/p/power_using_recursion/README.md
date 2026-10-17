# Power Using Recursion

Raise an integer base to a nonnegative integer exponent using the pinned linear recursive recurrence.

## Contract

- ABI: i64_array_scalar.
- Input is [base, exponent], where -10 <= base <= 10 and 0 <= exponent <= 15.
- Return base^exponent as a signed i64, with 0^0 = 1. Invalid framing, a null input pointer, or out-of-domain values return -1.
- The recurrence returns 1 at exponent zero; otherwise it returns base * power(base, exponent - 1).
- The bounds keep recursion depth at 15 and the result within signed i64. They also make Java's double return and Python's integer return agree exactly on the benchmark's integral outputs. Negative exponents are outside the function's domain because the recursive function itself does not terminate for them.

## Workload

[`workload.json`](workload.json) includes zero and unit bases, negative bases with odd and even exponents, source examples, maximum magnitude, and malformed and out-of-domain input. The [oracle](../../power_using_recursion_oracle.py) evaluates the bounded integer recurrence independently.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/power_using_recursion.c`](../../../c/power_using_recursion.c) |
| C3 | [`c3/power_using_recursion.c3`](../../../c3/power_using_recursion.c3) |
| C++ | [`cpp/power_using_recursion.cpp`](../../../cpp/power_using_recursion.cpp) |
| Elisa | [`elisa/power_using_recursion.elisa`](../../../elisa/power_using_recursion.elisa) |
| Nim | [`nim/power_using_recursion.nim`](../../../nim/power_using_recursion.nim) |
| Odin | [`odin/power_using_recursion.odin`](../../../odin/power_using_recursion.odin) |
| Rust | [`rust/power_using_recursion.rs`](../../../rust/power_using_recursion.rs) |
| V | [`v/power_using_recursion.v`](../../../v/power_using_recursion.v) |
| Zig | [`zig/power_using_recursion.zig`](../../../zig/power_using_recursion.zig) |

## Pinned sources

- [TheAlgorithms/Java PowerUsingRecursion.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/maths/PowerUsingRecursion.java) at e43ec3897e48f23843972d02cd05a5bb1b6864a2.
- [TheAlgorithms/Python power_using_recursion.py](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/power_using_recursion.py) at e1a2a8b016001309a73d5fec4818c35cca139795.

Both pinned functions recursively multiply by the base until the exponent reaches zero. The benchmark omits their command-line entry points.

## Build and record

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm power_using_recursion --language rust
python3 benchmarks/run_i64_array_scalar.py --algorithm power_using_recursion
```
