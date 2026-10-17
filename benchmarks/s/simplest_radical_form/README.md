# Simplest radical form

This benchmark adapts the pinned Lua `simplist_radical_form` routine. Its input is one signed 64-bit integer `[n]`, with `0 <= n <= 100,000,000`. The routine returns the pair `[coefficient, root_term]`, representing `sqrt(n) = coefficient * sqrt(root_term)`. For `n=0`, the source returns `(1,0)` before its positive-input assertion.

For positive n, the source tries every integer factor from 2 through `sqrt(n)`, where the upper bound is calculated once from the original input. It counts each factor's multiplicity, moves `factor^floor(count/2)` into the coefficient, multiplies one copy of the factor into `root_term` when the count is odd, then multiplies the remaining value into `root_term`. The bounded maximum keeps this trial division to at most 9,999 factor candidates and keeps the Lua number's integer arithmetic exact.

The `i64_array_bytes_output` ABI requires exactly one input value. Inputs outside the range or with malformed framing return `-1` and write no output. A valid input returns exactly two little-endian signed 64-bit values (16 bytes). A null output buffer or capacity below 16 returns `-2` without writing.

The independent oracle is [`benchmarks/simplest_radical_form_oracle.py`](../../simplest_radical_form_oracle.py). The workload covers zero, one, prime radicands, perfect squares, mixed factor multiplicities, a larger prime, the maximum input, and malformed or out-of-range inputs.

Pinned source: [TheAlgorithms/Lua `simplist_radical_form.lua`](https://github.com/TheAlgorithms/Lua/blob/cedc141018ad48884318fe08a6db278664b17128/src/math/simplist_radical_form.lua) at commit `cedc141018ad48884318fe08a6db278664b17128`.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/s/simplest_radical_form.c`](../../../c/s/simplest_radical_form.c) |
| C3 | [`c3/s/simplest_radical_form.c3`](../../../c3/s/simplest_radical_form.c3) |
| C++ | [`cpp/s/simplest_radical_form.cpp`](../../../cpp/s/simplest_radical_form.cpp) |
| Elisa | [`elisa/s/simplest_radical_form.elisa`](../../../elisa/s/simplest_radical_form.elisa) |
| Nim | [`nim/s/simplest_radical_form.nim`](../../../nim/s/simplest_radical_form.nim) |
| Odin | [`odin/s/simplest_radical_form.odin`](../../../odin/s/simplest_radical_form.odin) |
| Rust | [`rust/s/simplest_radical_form.rs`](../../../rust/s/simplest_radical_form.rs) |
| V | [`v/s/simplest_radical_form.v`](../../../v/s/simplest_radical_form.v) |
| Zig | [`zig/s/simplest_radical_form.zig`](../../../zig/s/simplest_radical_form.zig) |
