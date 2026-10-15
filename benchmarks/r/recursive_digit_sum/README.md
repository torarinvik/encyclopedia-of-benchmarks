# Recursive digit sum

The pinned Python source computes a super digit from a decimal string and a repetition count: sum the input digits, multiply by the count, then repeatedly sum the result's digits until one digit remains.

## Contract

- The binary scalar ABI receives `[number, repetitions]`. `number` represents the source decimal string; leading zeroes can be omitted because they do not affect its digit sum.
- `number` is in `[0, 2^63 - 1]` and repetitions are in `[0, 1,000,000]`.
- Invalid inputs return `-1`. Valid calls return the repeated digit sum, from 0 through 9.
- The bounded initial sum is at most 171, so multiplication remains within signed 64-bit range.

[`workload.json`](workload.json) covers the three source examples, zero and one repetitions, a single digit, and both numeric bounds.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/recursive_digit_sum.c`](../../../c/r/recursive_digit_sum.c) |
| C3 | [`c3/r/recursive_digit_sum.c3`](../../../c3/r/recursive_digit_sum.c3) |
| C++ | [`cpp/r/recursive_digit_sum.cpp`](../../../cpp/r/recursive_digit_sum.cpp) |
| Elisa | [`elisa/r/recursive_digit_sum.elisa`](../../../elisa/r/recursive_digit_sum.elisa) |
| Nim | [`nim/r/recursive_digit_sum.nim`](../../../nim/r/recursive_digit_sum.nim) |
| Odin | [`odin/r/recursive_digit_sum.odin`](../../../odin/r/recursive_digit_sum.odin) |
| Rust | [`rust/r/recursive_digit_sum.rs`](../../../rust/r/recursive_digit_sum.rs) |
| V | [`v/r/recursive_digit_sum.v`](../../../v/r/recursive_digit_sum.v) |
| Zig | [`zig/r/recursive_digit_sum.zig`](../../../zig/r/recursive_digit_sum.zig) |

## Upstream source

- [TheAlgorithms/Python `recursive_digit_sum.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/recursive_digit_sum.py)
