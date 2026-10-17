# Unbiased discrete range rescaling

This benchmark ports the generator returned by the pinned Lua `rescale` function. It maps a uniform integer draw from `[0, max)` to a uniform integer in `[0, new_max)` without modulo bias. The input supplies a deterministic stream of raw draws so each call has a fixed, reproducible input.

## Contract

- The `i64_array_scalar` input is `[max, new_max, draw_count, draws...]`, with exactly `3 + draw_count` values. `max` is 2 through 64, `new_max` is 1 through 256, `draw_count` is 1 through 256, and every draw is in `[0, max)`. Valid inputs contain at most 259 packed values; the parser admits 260 values so it can reject one over-bound draw count explicitly.
- One call to the source's returned generator is measured. The draw array supplies successive values from its `random()` callback. Values after the first successful result are ignored.
- When `max == new_max`, the first draw is returned. When downscaling, the source rejects draws greater than or equal to `max - (max % new_max)`, then returns the accepted draw modulo `new_max`.
- When upscaling, the source concatenates base-`max` draws until the accumulated range is at least `new_max`. If that range is larger than `new_max`, the same rejection rule removes the excess before taking the remainder. Exact powers of `max` return the accumulated value directly.
- A successful result is in `[0, new_max)`. Invalid packing, out-of-range values, or exhaustion of the supplied draw stream before a result is produced returns `-1`.

The bounds keep all intermediate powers and values within signed 64-bit range. A call consumes at most 256 supplied draws; exhaustion gives a defined error instead of waiting indefinitely for another random value.

## Pinned source and workload

The source is [TheAlgorithms/Lua `rescale.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/random/rescale.lua) at commit `cedc141018ad48884318fe08a6db278664b17128`. It returns the input random callback unchanged for equal ranges, rejects excess values when downscaling, and uses base-`max` digits plus rejection when upscaling.

[`workload.json`](workload.json) includes equal ranges, direct downscaling, rejected draws and retries, a target of one, exact-power upscaling, overshoot acceptance and rejection, trailing draws, maximum draw count, exhausted streams, and malformed inputs. The independent oracle is [`rescale_oracle.py`](../../rescale_oracle.py).

## Ports

| Language | Source |
| --- | --- |
| C | [`c/r/rescale.c`](../../../c/r/rescale.c) |
| C3 | [`c3/r/rescale.c3`](../../../c3/r/rescale.c3) |
| C++ | [`cpp/r/rescale.cpp`](../../../cpp/r/rescale.cpp) |
| Elisa | [`elisa/r/rescale.elisa`](../../../elisa/r/rescale.elisa) |
| Nim | [`nim/r/rescale.nim`](../../../nim/r/rescale.nim) |
| Odin | [`odin/r/rescale.odin`](../../../odin/r/rescale.odin) |
| Rust | [`rust/r/rescale.rs`](../../../rust/r/rescale.rs) |
| V | [`v/r/rescale.v`](../../../v/r/rescale.v) |
| Zig | [`zig/r/rescale.zig`](../../../zig/r/rescale.zig) |
