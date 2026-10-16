# Lua uint53 bit iterator

The pinned Lua module returns a stateless iterator yielding each bit from least significant to most significant and stops before leading zeroes. The scalar benchmark result is the number of bits yielded; zero yields none.

## Contract

Input is a one-element array [n], where 0 <= n < 2^53. Output is the bit length of n (0 for n=0). Invalid input returns -1.

See [workload](workload.json), [independent oracle](../../ibits_oracle.py), and pinned [Lua source](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/bit/uint53/ibits.lua).

| Language | Port |
|---|---|
| C | [`c/i/ibits.c`](../../../c/i/ibits.c) |
| C3 | [`c3/i/ibits.c3`](../../../c3/i/ibits.c3) |
| C++ | [`c++/i/ibits.cpp`](../../../c++/i/ibits.cpp) |
| Elisa | [`elisa/i/ibits.elisa`](../../../elisa/i/ibits.elisa) |
| Nim | [`nim/i/ibits.nim`](../../../nim/i/ibits.nim) |
| Odin | [`odin/i/ibits.odin`](../../../odin/i/ibits.odin) |
| Rust | [`rust/i/ibits.rs`](../../../rust/i/ibits.rs) |
| V | [`v/i/ibits.v`](../../../v/i/ibits.v) |
| Zig | [`zig/i/ibits.zig`](../../../zig/i/ibits.zig) |
