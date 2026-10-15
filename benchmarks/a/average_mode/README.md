# Average mode

Return the mode of an integer sequence when exactly one value has the highest frequency.

## Contract

- The `i64_array_scalar` ABI accepts between 1 and 64 signed 64-bit values.
- Each value must be an integer from 0 through 1,000.
- Valid inputs must have exactly one mode. The result is that value.
- Empty input, unsupported values, overlong input, or tied modes return `-1`.

## Source semantics

This follows the pinned [TheAlgorithms Python `average_mode.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/maths/average_mode.py) and [Julia `average_mode.jl`](https://github.com/TheAlgorithms/Julia/blob/384424b762bbb40d43f31001beeca0c6ffda2f1f/src/math/average_mode.jl). The Python source sorts its result; Julia preserves first-seen order. On the bounded integer subset with a unique mode, both return the same one-element list, which this scalar contract unwraps. Tied-mode results are outside the scalar contract and use the invalid sentinel.

## Workload

[`workload.json`](workload.json) covers unique modes, a singleton, all-equal input, documented examples, tied modes, empty input, and invalid value bounds.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/average_mode.c`](../../../c/a/average_mode.c) |
| C3 | [`c3/a/average_mode.c3`](../../../c3/a/average_mode.c3) |
| C++ | [`cpp/a/average_mode.cpp`](../../../cpp/a/average_mode.cpp) |
| Elisa | [`elisa/a/average_mode.elisa`](../../../elisa/a/average_mode.elisa) |
| Nim | [`nim/a/average_mode.nim`](../../../nim/a/average_mode.nim) |
| Odin | [`odin/a/average_mode.odin`](../../../odin/a/average_mode.odin) |
| Rust | [`rust/a/average_mode.rs`](../../../rust/a/average_mode.rs) |
| V | [`v/a/average_mode.v`](../../../v/a/average_mode.v) |
| Zig | [`zig/a/average_mode.zig`](../../../zig/a/average_mode.zig) |

The package uses the `i64_array_scalar` benchmark ABI.
