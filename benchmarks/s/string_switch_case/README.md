# String switch case

This benchmark preserves the pinned Python module's case-conversion modes:
simple case, Pascal case, camel case, configurable complex case, snake case,
and kebab case. The source first splits on punctuation outside ASCII letters,
digits, and whitespace, then splits each resulting group on whitespace. It
discards punctuation; simple/Pascal/camel concatenate capitalized words,
while complex/snake/kebab join whitespace-separated words inside each
punctuation group and concatenate the groups without a separator.

## Contract

Input is a packed signed-i64 array
`[mode, separator_byte, text_length, ASCII bytes...]`. Modes are 0 simple, 1
Pascal, 2 camel, 3 custom-separator lowercase, 4 custom-separator uppercase,
5 snake lowercase, 6 snake uppercase, 7 kebab lowercase, and 8 kebab uppercase.
Modes 3 and 4 use `separator_byte` as one ASCII separator; all other modes
require it to be zero. The text is 0 to 1,024 7-bit ASCII bytes. Python
whitespace splitting is preserved, including ASCII controls 0x1c through
0x1f. Other punctuation bytes split groups and are discarded.

The output is raw bytes, not NUL-terminated. Empty camel input returns the
source's literal `not valid string`; the other empty conversions return empty
output. Invalid packed input returns `-1`, insufficient capacity returns
`-2`, and successful calls return the output byte length. Maximum input length
is 1,027 signed-i64 values and maximum output capacity is 1,024 bytes.

## Workload and oracle

[`workload.json`](workload.json) exercises all nine modes, custom and NUL
separators, punctuation group boundaries, digits, empty input, the maximum
text length, malformed headers/bytes, and insufficient capacity. The
independent oracle is [`string_switch_case_oracle.py`](../../string_switch_case_oracle.py).

Pinned source: [TheAlgorithms/Python `string_switch_case.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/string_switch_case.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/s/string_switch_case.c](../../../c/s/string_switch_case.c) |
| C3 | [c3/s/string_switch_case.c3](../../../c3/s/string_switch_case.c3) |
| C++ | [cpp/s/string_switch_case.cpp](../../../cpp/s/string_switch_case.cpp) |
| Elisa | [elisa/s/string_switch_case.elisa](../../../elisa/s/string_switch_case.elisa) |
| Nim | [nim/s/string_switch_case.nim](../../../nim/s/string_switch_case.nim) |
| Odin | [odin/s/string_switch_case.odin](../../../odin/s/string_switch_case.odin) |
| Rust | [rust/s/string_switch_case.rs](../../../rust/s/string_switch_case.rs) |
| V | [v/s/string_switch_case.v](../../../v/s/string_switch_case.v) |
| Zig | [zig/s/string_switch_case.zig](../../../zig/s/string_switch_case.zig) |

## Verification

Run `python3 benchmarks/verify_i64_array_bytes_output.py --algorithm string_switch_case --languages rust` to check the port against the independent oracle.
