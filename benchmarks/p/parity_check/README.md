# Parity check

Return 1 when the pinned Java [`ParityCheck.checkParity`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/bitmanipulation/ParityCheck.java) counts an even number of set bits, and 0 otherwise.

## Contract

- Input is one signed 32-bit integer.
- For nonnegative inputs, return 1 when the popcount is even and 0 when it is odd.
- The Java source only loops while `n > 0`, so every negative input returns 1. Zero also returns 1.
- An input outside the signed 32-bit range returns `-1`.

[`workload.json`](workload.json) covers the source examples, zero, negative values, signed boundaries, and invalid input.

| Language | Source |
| --- | --- |
| C | [`c/p/parity_check.c`](../../../c/p/parity_check.c) |
| C3 | [`c3/p/parity_check.c3`](../../../c3/p/parity_check.c3) |
| C++ | [`cpp/p/parity_check.cpp`](../../../cpp/p/parity_check.cpp) |
| Elisa | [`elisa/p/parity_check.elisa`](../../../elisa/p/parity_check.elisa) |
| Nim | [`nim/p/parity_check.nim`](../../../nim/p/parity_check.nim) |
| Odin | [`odin/p/parity_check.odin`](../../../odin/p/parity_check.odin) |
| Rust | [`rust/p/parity_check.rs`](../../../rust/p/parity_check.rs) |
| V | [`v/p/parity_check.v`](../../../v/p/parity_check.v) |
| Zig | [`zig/p/parity_check.zig`](../../../zig/p/parity_check.zig) |

The benchmark uses the `scalar` ABI.
