# Integer to String in Bases 2 through 16

This package ports the pinned C `int_to_string` routine. It repeatedly extracts the remainder in the selected base, reverses the collected digits, and terminates the resulting lowercase string with a NUL byte.

## Contract

- Pack the source pair `(value, base)` into the scalar input as `value * 15 + (base - 2)`. The port decodes `value` in `[0, 65535]` and `base` in `[2, 16]`.
- Output digits use `0`–`9` and lowercase `a`–`f`, followed by one NUL byte. The return value is the byte count including that terminator.
- Packed inputs that decode to values above 65535 return `-1`; insufficient output capacity returns `-2`.

The packed representation is unambiguous because the base offset uses all 15 values from 0 through 14. [`workload.json`](workload.json) covers the source's decimal, octal, and hexadecimal examples, the binary base, and uint16 boundaries.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/i/int_to_string.c`](../../../c/i/int_to_string.c) |
| C3 | [`c3/i/int_to_string.c3`](../../../c3/i/int_to_string.c3) |
| C++ | [`cpp/i/int_to_string.cpp`](../../../cpp/i/int_to_string.cpp) |
| Elisa | [`elisa/i/int_to_string.elisa`](../../../elisa/i/int_to_string.elisa) |
| Nim | [`nim/i/int_to_string.nim`](../../../nim/i/int_to_string.nim) |
| Odin | [`odin/i/int_to_string.odin`](../../../odin/i/int_to_string.odin) |
| Rust | [`rust/i/int_to_string.rs`](../../../rust/i/int_to_string.rs) |
| V | [`v/i/int_to_string.v`](../../../v/i/int_to_string.v) |
| Zig | [`zig/i/int_to_string.zig`](../../../zig/i/int_to_string.zig) |

## Upstream source

- [TheAlgorithms/C `int_to_string.c`](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/conversions/int_to_string.c)
