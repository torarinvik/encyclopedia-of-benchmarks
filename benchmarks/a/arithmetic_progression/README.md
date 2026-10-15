# Arithmetic progression sum

The pinned Lua function returns the sum of an inclusive arithmetic progression. It computes `count = floor((to - from) / step)`, then `last = from + count * step`, and returns `(count + 1) * (from + last) / 2`.

## Contract

- The packed input is exactly `[from, to, step]`, using signed 64-bit integers.
- `from` and `to` are in `[-1,000,000, 1,000,000]`; `step` is nonzero and in the same range.
- For `from < to`, `step` must be positive. For `from > to`, `step` must be negative. When `from == to`, either sign is valid.
- The sum includes `from` and the last progression term that does not pass `to`. Equal endpoints produce the one-term sum `from`.
- Invalid lengths, bounds, or step directions return `-1`.

The source defaults an omitted step to `1`, but the benchmark's packed ABI supplies all three values explicitly; pass `1` to represent the default. In the Lua source, the descending-interval assertion runs before the default is applied, so a descending interval with an omitted step errors. Zero step also fails during division/flooring. The contract uses valid, sign-matched nonzero steps.

Under these bounds, the quotient is at most 2,000,000, all integer intermediates are exact in Lua's binary64 number representation, and `(count + 1) * (from + last)` stays below `2^53` and within signed 64-bit range. The final division by two is exact because it is the sum of integer progression terms.

The packed scalar ABI is:

```c
int64_t arithmetic_progression(const int64_t *values, size_t length);
```

## Workload

[`workload.json`](workload.json) includes positive and negative sums, ascending and descending intervals, a singleton, a step that does not land exactly on `to`, and input boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/arithmetic_progression.c`](../../../c/a/arithmetic_progression.c) |
| C3 | [`c3/a/arithmetic_progression.c3`](../../../c3/a/arithmetic_progression.c3) |
| C++ | [`cpp/a/arithmetic_progression.cpp`](../../../cpp/a/arithmetic_progression.cpp) |
| Elisa | [`elisa/a/arithmetic_progression.elisa`](../../../elisa/a/arithmetic_progression.elisa) |
| Nim | [`nim/a/arithmetic_progression.nim`](../../../nim/a/arithmetic_progression.nim) |
| Odin | [`odin/a/arithmetic_progression.odin`](../../../odin/a/arithmetic_progression.odin) |
| Rust | [`rust/a/arithmetic_progression.rs`](../../../rust/a/arithmetic_progression.rs) |
| V | [`v/a/arithmetic_progression.v`](../../../v/a/arithmetic_progression.v) |
| Zig | [`zig/a/arithmetic_progression.zig`](../../../zig/a/arithmetic_progression.zig) |

## Upstream source

- [TheAlgorithms/Lua `arithmetic_progression.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/sum/arithmetic_progression.lua)
