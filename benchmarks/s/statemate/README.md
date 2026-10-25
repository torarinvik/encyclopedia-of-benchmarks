# Embench-IoT Statemate fixed control-path profile

This package models the fixed no-stimulus execution path of Embench-IoT's
generated car-window StateChart. Each run resets its state, advances its
default state entries until stable, and returns the same snapshot checked by
the source verifier.

## Contract

The i64_array_bytes_output input is exactly [run_count], where run_count is
1–256. The function performs that many reset-and-settle runs and returns the
last source-profile snapshot as 92 bytes:

- 64 one-byte Bitlist entries, each 0 or 1;
- 16 state identifiers in the order checked by the source verifier;
- three 32-bit little-endian timer values.

The source no-stimulus workload produces Bitlist entry 5 set, the other
Bitlist entries clear, state identifiers
[0, 0, 0, 3, 2, 1, 1, 0, 0, 0, 0, 0, 2, 1, 0, 1], and three zero timers.
Malformed input returns -1. A null output pointer or capacity below 92
returns -2 without writing output.

This is the source workload's fixed initialization and settlement trajectory,
not a general StateChart engine or a port of its input-driven branches. The
oracle is [statemate_oracle.py](../../statemate_oracle.py), and the fixture is
in [workload.json](workload.json).

## Provenance and rights

Source:
[src/statemate/libstatemate.c](https://github.com/embench/embench-iot/blob/de24bdf561f4eaad7f37685641fa301f2b8b4bc3/src/statemate/libstatemate.c)
at Embench-IoT commit
[de24bdf561f4eaad7f37685641fa301f2b8b4bc3](https://github.com/embench/embench-iot/commit/de24bdf561f4eaad7f37685641fa301f2b8b4bc3).
The generated source declares GPL-3.0-or-later and describes an experimental
car-window lift controller. This package carries that license in
[LICENSE.txt](LICENSE.txt). Its state settlement code is independently
written from the source verifier contract; no upstream implementation code
was copied or translated.

| Language | Port |
| --- | --- |
| C | [statemate.c](../../../c/s/statemate.c) |
| C3 | [statemate.c3](../../../c3/s/statemate.c3) |
| C++ | [statemate.cpp](../../../cpp/s/statemate.cpp) |
| Elisa | [statemate.elisa](../../../elisa/s/statemate.elisa) |
| Nim | [statemate.nim](../../../nim/s/statemate.nim) |
| Odin | [statemate.odin](../../../odin/s/statemate.odin) |
| Rust | [statemate.rs](../../../rust/s/statemate.rs) |
| V | [statemate.v](../../../v/s/statemate.v) |
| Zig | [statemate.zig](../../../zig/s/statemate.zig) |
