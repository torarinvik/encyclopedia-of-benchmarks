# Strip characters from a string

This benchmark follows the pinned Python `strip` function. It removes any leading and trailing characters that occur in the supplied character set; by default, that set is space, tab, line feed, and carriage return. It leaves interior characters untouched and returns an empty string when every character is stripped.

## Contract

Input is `[text_length, ASCII text bytes..., character_length, ASCII strip-set bytes...]`. A `character_length` of `-1` selects the source default set and must be the final input value; a length from 0 to 128 selects an explicit set. Text is limited to 256 ASCII bytes. Output is the remaining bytes in their original order. Invalid input returns `-1`; insufficient output capacity returns `-2` without writing output. Runtime oracle: `strip_oracle.py`.

The pinned Python source scans inward from both ends while each character belongs to the set, then returns the original slice. The bounded ASCII contract avoids cross-language differences in Unicode character classification while preserving the algorithm's membership and boundary behavior.

Pinned source: [Python `strip.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/strip.py).

## Language ports

| Language | Source |
| --- | --- |
| C | [c/s/strip.c](../../../c/s/strip.c) |
| C3 | [c3/s/strip.c3](../../../c3/s/strip.c3) |
| C++ | [cpp/s/strip.cpp](../../../cpp/s/strip.cpp) |
| Elisa | [elisa/s/strip.elisa](../../../elisa/s/strip.elisa) |
| Nim | [nim/s/strip.nim](../../../nim/s/strip.nim) |
| Odin | [odin/s/strip.odin](../../../odin/s/strip.odin) |
| Rust | [rust/s/strip.rs](../../../rust/s/strip.rs) |
| V | [v/s/strip.v](../../../v/s/strip.v) |
| Zig | [zig/s/strip.zig](../../../zig/s/strip.zig) |
