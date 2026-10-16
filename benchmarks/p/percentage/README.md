# Scaled percentage

This benchmark implements the pinned Solidity `uint256Percentage(a, b, dp)` method. It computes `(a * b * 10^dp) / 100` using integer division, returning the scaled result to be divided by `10^dp` by a caller. Solidity reverts when any input is zero or when the scaled numerator is less than 100.

## Contract

Input is `[a, b, dp]`, with `a` and `b` in 1 through 100,000 and `dp` in 1 through 4. The bound keeps the intermediate product in signed 64-bit range. Output is the integer quotient, or `-1` for invalid inputs or the source’s numerator threshold revert. The separate signed `int256Percentage` method in the same Solidity file is outside this benchmark.

See [`workload.json`](workload.json) and the runtime [oracle](../../percentage_oracle.py). Pinned source: [TheAlgorithms/Solidity `Percentage.sol`](https://github.com/TheAlgorithms/Solidity/blob/08cba51fb38e276062b0c9791d7e0ee494ffa903/src/Maths/Percentage.sol).

| Language | Port |
|---|---|
| C | [`c/p/percentage.c`](../../../c/p/percentage.c) |
| C3 | [`c3/p/percentage.c3`](../../../c3/p/percentage.c3) |
| C++ | [`cpp/p/percentage.cpp`](../../../cpp/p/percentage.cpp) |
| Elisa | [`elisa/p/percentage.elisa`](../../../elisa/p/percentage.elisa) |
| Nim | [`nim/p/percentage.nim`](../../../nim/p/percentage.nim) |
| Odin | [`odin/p/percentage.odin`](../../../odin/p/percentage.odin) |
| Rust | [`rust/p/percentage.rs`](../../../rust/p/percentage.rs) |
| V | [`v/p/percentage.v`](../../../v/p/percentage.v) |
| Zig | [`zig/p/percentage.zig`](../../../zig/p/percentage.zig) |
