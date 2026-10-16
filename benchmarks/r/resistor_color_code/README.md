# Resistor color code

This benchmark adapts the pinned [TheAlgorithms/Python `electronics/resistor_color_code.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/electronics/resistor_color_code.py). It preserves the source's significant-band roles, multiplier and tolerance choices, default 20% tolerance, six-band temperature coefficient, and exact `resistance` string formatting.

## Contract

- Input is `[byte_length, ASCII bytes...]`, where the payload is a comma-separated list of 3 through 6 exact color names with no spaces. Names are case-sensitive and must be one of `Black,Brown,Red,Orange,Yellow,Green,Blue,Violet,Grey,White,Gold,Silver`. The payload is at most 41 bytes. Invalid shape, non-ASCII bytes, unknown colors, or colors invalid for their band role return `-1`.
- The first two bands (3/4-band resistors) or first three bands (5/6-band resistors) are significant digits and must use `Black` through `White`. The next band is a multiplier (`Black` through `Silver`). Four-or-more-band resistors require a tolerance color from `Brown,Red,Orange,Yellow,Green,Blue,Violet,Grey,Gold,Silver`; 6-band resistors require a final temperature color from `Black` through `Grey`.
- Output is the UTF-8 encoding of the exact `resistance` string returned by Python, without the surrounding dictionary. It includes `Ω`, `±`, and the source's trailing space for 3–5 bands. Positive-power multipliers produce integer resistance text; Gold/Silver multipliers preserve Python's float spelling (for example `1.0`, `0.5`, `0.05`). Insufficient output capacity returns `-2`; success returns the number of UTF-8 bytes written.
- The source raises `ValueError` for invalid band counts, colors, or role assignments. This ABI maps those invalid inputs to `-1`.

The independent oracle is [`benchmarks/resistor_color_code_oracle.py`](../../resistor_color_code_oracle.py). Its workload covers 3–6 bands, leading zero digits, integer and fractional multipliers/tolerances, temperature coefficients, invalid role assignments, and output capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/r/resistor_color_code.c`](../../../c/r/resistor_color_code.c) |
| C3 | [`c3/r/resistor_color_code.c3`](../../../c3/r/resistor_color_code.c3) |
| C++ | [`cpp/r/resistor_color_code.cpp`](../../../cpp/r/resistor_color_code.cpp) |
| Elisa | [`elisa/r/resistor_color_code.elisa`](../../../elisa/r/resistor_color_code.elisa) |
| Nim | [`nim/r/resistor_color_code.nim`](../../../nim/r/resistor_color_code.nim) |
| Odin | [`odin/r/resistor_color_code.odin`](../../../odin/r/resistor_color_code.odin) |
| Rust | [`rust/r/resistor_color_code.rs`](../../../rust/r/resistor_color_code.rs) |
| V | [`v/r/resistor_color_code.v`](../../../v/r/resistor_color_code.v) |
| Zig | [`zig/r/resistor_color_code.zig`](../../../zig/r/resistor_color_code.zig) |
