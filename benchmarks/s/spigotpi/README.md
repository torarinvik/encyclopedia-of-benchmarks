# Spigot digits of pi

This benchmark ports the pinned Go `Spigot(n)` routine. It returns the first `n` decimal digits of pi as ASCII bytes, beginning with `3` and without a decimal point. The ports preserve the source's spigot digit-generation and carry handling, using bounded stack storage for the approved input range.

## Contract

- Input is exactly `[n]`, where `n` is from 0 through 256.
- Output is exactly the first `n` ASCII digits of pi, beginning with `3`, with no decimal point or terminator. `n = 0` produces empty output. The independent Decimal oracle computes guard digits and truncates to `n`; it does not round the last requested digit.
- Invalid input shape or range returns `-1`. A null output pointer or insufficient capacity returns `-2` without writing. Success returns the byte length.
- [`workload.json`](workload.json) records bounded, malformed, null-pointer, and capacity cases. The independent [`spigotpi_oracle.py`](../../spigotpi_oracle.py) uses the Chudnovsky series with Python `Decimal` and truncates after computing guard digits.

## Pinned source

[TheAlgorithms/Go `spigotpi.go`](https://github.com/TheAlgorithms/Go/blob/5ba447ec5ff3d1213de65b92e726ee74c5d5cc19/math/pi/spigotpi.go), commit `5ba447ec5ff3d1213de65b92e726ee74c5d5cc19`, method `Spigot(n)`.

## Ports

| Language | Source |
| --- | --- |
| C | [`c/spigotpi.c`](../../../c/m/spigotpi.c) |
| C3 | [`c3/spigotpi.c3`](../../../c3/m/spigotpi.c3) |
| C++ | [`cpp/spigotpi.cpp`](../../../cpp/m/spigotpi.cpp) |
| Elisa | [`elisa/spigotpi.elisa`](../../../elisa/m/spigotpi.elisa) |
| Nim | [`nim/spigotpi.nim`](../../../nim/m/spigotpi.nim) |
| Odin | [`odin/spigotpi.odin`](../../../odin/m/spigotpi.odin) |
| Rust | [`rust/spigotpi.rs`](../../../rust/m/spigotpi.rs) |
| V | [`v/spigotpi.v`](../../../v/m/spigotpi.v) |
| Zig | [`zig/spigotpi.zig`](../../../zig/m/spigotpi.zig) |
