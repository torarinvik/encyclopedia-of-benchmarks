# Relativity formulas

This package ports the pinned Java utility's Lorentz factor, length contraction, time dilation, and relativistic velocity addition methods.

## Contract

Input is exactly `[operation, arg1_milli, arg2_milli]`; one trailing value is admitted by the parser for malformed-input coverage. Every used physical value is divided by 1,000. Operation `0` computes gamma for velocity `arg1_milli`; `arg2_milli` must be zero. Operation `1` contracts length `arg1_milli` at velocity `arg2_milli`. Operation `2` dilates time `arg1_milli` at velocity `arg2_milli`. Operation `3` adds `arg1_milli` and frame velocity `arg2_milli` using the source's velocity-addition formula.

Lengths and times are bounded to raw milli-values 0..1,000,000, representing [0, 1,000] physical units. Velocity fields are bounded by the speed of light, `c = 299792458 m/s`, represented as raw ±299,792,458,000; the gamma, length-contraction, time-dilation, and frame-velocity arguments require strict `|v| < c`. Velocity addition's first velocity follows the source's distinct rule and permits `|v1| == c`. Invalid input or a source-domain exception returns `-1e300`. Output comparison uses absolute and relative tolerances of `1e-12`.

The formulas preserve the source order: `1 / sqrt(1 - v*v/(c*c))`, `length / gamma(v)`, `time * gamma(v)`, and `(v1-v) / (1 - v1*v/(c*c))`.

Pinned source: [Relativity.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/physics/Relativity.java). See [workload](workload.json) and [oracle](../../relativity_oracle.py).

| Language | Port |
|---|---|
| C | ../../../c/r/relativity.c |
| C3 | ../../../c3/r/relativity.c3 |
| C++ | ../../../cpp/r/relativity.cpp |
| Elisa | ../../../elisa/r/relativity.elisa |
| Nim | ../../../nim/r/relativity.nim |
| Odin | ../../../odin/r/relativity.odin |
| Rust | ../../../rust/r/relativity.rs |
| V | ../../../v/r/relativity.v |
| Zig | ../../../zig/r/relativity.zig |
