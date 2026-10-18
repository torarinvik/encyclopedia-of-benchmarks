# LINQ shuffler

This benchmark preserves the seeded path of the pinned C# `LinqShuffler<T>`:
it asks `Random.Next()` once per input element, then orders elements by those
random keys with LINQ's stable ascending `OrderBy`.

## Contract

Input is `[n, seed, value...]`. `n` is from 0 through 64; `seed` and each value
are signed 32-bit integers. The input length must be exactly `n + 2`. Output is
`[n, shuffled_value...]`, encoded as little-endian signed 64-bit words. The
count word is present for empty input, so output uses at most 65 words (520
bytes).

The benchmark fixes seeded `System.Random` behavior to the base class's
compatibility generator in .NET 6.0.0. `seed == -2147483648` uses
`2147483647` as the initialization magnitude; every other seed uses its
absolute value. Initialize a 56-entry integer array `S` with `S[0] = 0`,
`MBIG = 2147483647`, `MSEED = 161803398`, and:

1. Set `mj = MSEED - initialization_magnitude`, `S[55] = mj`, and `mk = 1`.
2. For `i = 1..54`, set `ii = (21 * i) mod 55`, then `S[ii] = mk`; update
   `mk = mj - mk`, add `MBIG` once if `mk < 0`, and set `mj = S[ii]`.
3. Repeat four times: for `i = 1..55`, subtract
   `S[1 + (i + 30) mod 55]` from `S[i]`, then add `MBIG` once if the result is
   negative.
4. Set the two sample indices to `inext = 0` and `inextp = 21`.

To produce one `Next()` key, increment each index and wrap it to 1 when it
reaches 56. Compute `sample = S[inext] - S[inextp]`; decrement it if it equals
`MBIG`, add `MBIG` once if it is negative, store it in `S[inext]`, and return
it. This yields a key from 0 through 2147483646. Generate keys in input order
and sort by `(key, original_index)`, which makes the stable tie behavior
explicit. This is random-key sorting, not Fisher–Yates.

Invalid framing, out-of-range fields, or a null input return `-1` before output
checks. A null output pointer or capacity below the required byte count returns
`-2`; errors leave the output untouched. Empty input still needs an 8-byte
output buffer. [`workload.json`](workload.json) covers zero and edge seeds,
duplicate values, empty and singleton arrays, malformed framing, invalid
fields, output capacity, and error precedence. The independent oracle is
[`benchmarks/linqshuffler_oracle.py`](../../linqshuffler_oracle.py).

## Pinned sources

- [TheAlgorithms/C-Sharp `LINQShuffler.cs`](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Shufflers/LINQShuffler.cs)
- [.NET 6.0.0 `System.Random`](https://github.com/dotnet/runtime/blob/v6.0.0/src/libraries/System.Private.CoreLib/src/System/Random.cs), which selects the seeded compatibility implementation for `new Random(seed)` and defines `Next()` as a nonnegative `int` below `Int32.MaxValue`.
- [.NET 6.0.0 seeded compatibility implementation](https://github.com/dotnet/runtime/blob/v6.0.0/src/libraries/System.Private.CoreLib/src/System/Random.Net5CompatImpl.cs), which defines the subtractive `CompatPrng` initialization and sample step specified above.

The oracle spells out the compatibility algorithm above, so benchmark results do
not depend on the installed .NET runtime.

## Language ports

| Language | Source |
| --- | --- |
| C | [`c/l/linqshuffler.c`](../../../c/l/linqshuffler.c) |
| C3 | [`c3/l/linqshuffler.c3`](../../../c3/l/linqshuffler.c3) |
| C++ | [`cpp/l/linqshuffler.cpp`](../../../cpp/l/linqshuffler.cpp) |
| Elisa | [`elisa/l/linqshuffler.elisa`](../../../elisa/l/linqshuffler.elisa) |
| Nim | [`nim/l/linqshuffler.nim`](../../../nim/l/linqshuffler.nim) |
| Odin | [`odin/l/linqshuffler.odin`](../../../odin/l/linqshuffler.odin) |
| Rust | [`rust/l/linqshuffler.rs`](../../../rust/l/linqshuffler.rs) |
| V | [`v/l/linqshuffler.v`](../../../v/l/linqshuffler.v) |
| Zig | [`zig/l/linqshuffler.zig`](../../../zig/l/linqshuffler.zig) |
