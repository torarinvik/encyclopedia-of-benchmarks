# Lua uint53 predicate

The pinned Lua `is` function returns true only for a number whose value is integral, nonnegative, and less than `2^53`. The bounded integer-array interface supplies one signed 64-bit integer, so the predicate reduces exactly to that range check.

## Contract

Input is a one-element array `[n]` with any signed 64-bit integer. Output is 1 iff `0 <= n < 2^53`, otherwise 0. Invalid array shapes return -1.

See [workload](workload.json), [independent oracle](../../is_oracle.py), and pinned [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/is.lua).

| Language | Port |
|---|---|
| C | [`c/i/uint53_is.c`](../../../c/i/uint53_is.c) |
| C3 | [`c3/i/uint53_is.c3`](../../../c3/i/uint53_is.c3) |
| C++ | [`c++/i/uint53_is.cpp`](../../../c++/i/uint53_is.cpp) |
| Elisa | [`elisa/i/uint53_is.elisa`](../../../elisa/i/uint53_is.elisa) |
| Nim | [`nim/i/uint53_is.nim`](../../../nim/i/uint53_is.nim) |
| Odin | [`odin/i/uint53_is.odin`](../../../odin/i/uint53_is.odin) |
| Rust | [`rust/i/uint53_is.rs`](../../../rust/i/uint53_is.rs) |
| V | [`v/i/uint53_is.v`](../../../v/i/uint53_is.v) |
| Zig | [`zig/i/uint53_is.zig`](../../../zig/i/uint53_is.zig) |
