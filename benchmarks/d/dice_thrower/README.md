# Dice Thrower

Enumerate every ordered sequence of standard die faces whose values sum to a target. The package follows the recursive Java `getDiceCombinations` method and serializes its returned list as newline-delimited ASCII.

## Contract

- Input is one signed 64-bit integer target in 0..8, passed in the `i64_array_bytes_output_call` input array.
- At each recursion level, try face values 1 through 6 in ascending order, stopping at the remaining target. When the remaining target is zero, emit the accumulated face digits followed by LF. Preserve this depth-first face order.
- The function returns the number of output bytes written. Targets outside 0..8 or malformed input return -1. Insufficient output capacity returns -2 and writes no bytes.
- The output workspace is 696 bytes, enough for target 8. For target zero the source returns a list with one empty string, encoded as a single LF byte. For positive targets, every source string is nonempty.

## Source semantics and distinction

This follows the pinned [Java `DiceThrower.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/recursion/DiceThrower.java) at commit `e43ec3897e48f23843972d02cd05a5bb1b6864a2`. Its recursive helper builds strings by appending a face digit and returns each complete sequence in ascending face traversal order. The newline byte is the benchmark's lossless encoding between list items; source strings contain only digits 1 through 6.

This contract differs from [`dice_throw`](../dice_throw/README.md), which counts ways to reach a target using a fixed number of dice with a configurable number of faces. `dice_thrower` enumerates ordered compositions with any number of standard six-sided die rolls.

## Workload

[`workload.json`](workload.json) covers target zero's empty string, a single face, the pinned target-four enumeration, maximum target eight, invalid targets, malformed input, and insufficient output capacity.

Build with the `i64_array_bytes_output` family.

Verify every port against the bounded recursive oracle and workload using `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm dice_thrower`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/dice_thrower.c`](../../../c/d/dice_thrower.c) |
| C3 | [`c3/d/dice_thrower.c3`](../../../c3/d/dice_thrower.c3) |
| C++ | [`cpp/d/dice_thrower.cpp`](../../../cpp/d/dice_thrower.cpp) |
| Elisa | [`elisa/d/dice_thrower.elisa`](../../../elisa/d/dice_thrower.elisa) |
| Nim | [`nim/d/dice_thrower.nim`](../../../nim/d/dice_thrower.nim) |
| Odin | [`odin/d/dice_thrower.odin`](../../../odin/d/dice_thrower.odin) |
| Rust | [`rust/d/dice_thrower.rs`](../../../rust/d/dice_thrower.rs) |
| V | [`v/d/dice_thrower.v`](../../../v/d/dice_thrower.v) |
| Zig | [`zig/d/dice_thrower.zig`](../../../zig/d/dice_thrower.zig) |
