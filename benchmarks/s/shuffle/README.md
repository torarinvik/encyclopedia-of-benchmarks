# Shuffle

This package covers the pinned Lua forward Fisher–Yates shuffle. The Lua closure mutates its list in place, makes one inclusive `math.random(i, #list)` call for each `i` from 1 through `#list - 1`, then swaps `list[i]` with `list[j]`; it returns no value. The benchmark exposes the resulting list as output and supplies each bounded random choice explicitly so every language replays the same swaps.

## Contract

The ABI is `float64_slice_io`. Input is `[n, values..., offsets...]`, where `n` is an exact integer from 0 through 256, followed by exactly `n` signed i32 values and `max(n-1, 0)` draw offsets. Every value and offset is an exactly represented integer. For each zero-based iteration `i` from 0 through `n-2`, the corresponding offset must be in `[0, n-1-i]`; the selected index is `j = i + offset`. The implementation applies swaps in forward order. These offsets represent the Lua call's inclusive result `j` shifted to zero-based indices. They preserve the source's draw count and swap mapping without relying on Lua's process-global RNG or a Lua-version-specific seed sequence. No RNG algorithm or seed is part of this contract. Independent uniform offsets produce the standard Fisher–Yates permutation distribution.

An empty or singleton list consumes no offsets. Malformed framing, out-of-range values, fractional values or offsets, and invalid offsets return `-1` before output checks. A null output pointer or capacity below `n` returns `-2` without writes, including a null pointer for an empty valid list. A non-null output with zero capacity succeeds for the empty list and returns zero. The output is the shuffled sequence as exactly represented float64 values; the result is the number of values. The returned output is the benchmark representation of the Lua closure's in-place mutation.

## Pinned source

- Lua `shuffle.lua` at commit `cedc141018ad48884318fe08a6db278664b17128`: https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/random/shuffle.lua

## Workload and oracle

- Workload: [`workload.json`](workload.json)
- Oracle: [`shuffle_oracle.py`](../../shuffle_oracle.py)

## Ports

| Language | Port |
| --- | --- |
| C | [`c/s/shuffle.c`](../../../c/s/shuffle.c) |
| C3 | [`c3/s/shuffle.c3`](../../../c3/s/shuffle.c3) |
| C++ | [`cpp/s/shuffle.cpp`](../../../cpp/s/shuffle.cpp) |
| Elisa | [`elisa/s/shuffle.elisa`](../../../elisa/s/shuffle.elisa) |
| Nim | [`nim/s/shuffle.nim`](../../../nim/s/shuffle.nim) |
| Odin | [`odin/s/shuffle.odin`](../../../odin/s/shuffle.odin) |
| Rust | [`rust/s/shuffle.rs`](../../../rust/s/shuffle.rs) |
| V | [`v/s/shuffle.v`](../../../v/s/shuffle.v) |
| Zig | [`zig/s/shuffle.zig`](../../../zig/s/shuffle.zig) |
