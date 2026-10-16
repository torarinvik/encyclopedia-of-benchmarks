# Common characters frequency quotient

This benchmark preserves the behavior of the pinned Ruby implementation in
`common_characters.rb`, including its difference from the challenge's stated
intersection semantics. The challenge asks for each character's minimum
frequency across all strings. The implementation instead counts each
character across the entire array and emits `floor(total_frequency /
string_count)` copies. For example, `['aa', 'b']` emits `['a']`, even though
`b` contains no `a`. The benchmark name calls out this source behavior so it
is not confused with a correct per-string intersection algorithm.

The challenge permits results in any order, so this contract sorts output
bytes in ascending ASCII order to make results deterministic.

## Contract

Input is a packed signed-i64 array `[string_count, length_0, bytes_0, ...]`.
There are 0 to 16 strings; each string has 0 to 64 lowercase ASCII letters,
with at most 512 characters total. Empty strings are valid. The packed input
has at most 1,041 values. Invalid input returns `-1`; insufficient output
capacity returns `-2`; success returns the output byte count. Output is raw
lowercase ASCII bytes without a terminator and is at most 64 bytes. For zero
strings, encoded as `[0]`, output is empty.

## Source and workload

Pinned source: [TheAlgorithms/Ruby `common_characters.rb`](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/hash_table/common_characters.rb) at commit `bda11bdfd83b7958e1ca98247e5e43100ca88865`.

[`workload.json`](workload.json) includes the examples, duplicate frequencies,
concentrated counts that distinguish the source formula from the challenge
text, empty inputs, maximum sizes, malformed arrays, and short output buffers.
The independent oracle is [`common_characters_frequency_quotient_oracle.py`](../../common_characters_frequency_quotient_oracle.py).

## Implementations

| Language | Source |
| --- | --- |
| C | [c/c/common_characters_frequency_quotient.c](../../../c/c/common_characters_frequency_quotient.c) |
| C3 | [c3/c/common_characters_frequency_quotient.c3](../../../c3/c/common_characters_frequency_quotient.c3) |
| C++ | [cpp/c/common_characters_frequency_quotient.cpp](../../../cpp/c/common_characters_frequency_quotient.cpp) |
| Elisa | [elisa/c/common_characters_frequency_quotient.elisa](../../../elisa/c/common_characters_frequency_quotient.elisa) |
| Nim | [nim/c/common_characters_frequency_quotient.nim](../../../nim/c/common_characters_frequency_quotient.nim) |
| Odin | [odin/c/common_characters_frequency_quotient.odin](../../../odin/c/common_characters_frequency_quotient.odin) |
| Rust | [rust/c/common_characters_frequency_quotient.rs](../../../rust/c/common_characters_frequency_quotient.rs) |
| V | [v/c/common_characters_frequency_quotient.v](../../../v/c/common_characters_frequency_quotient.v) |
| Zig | [zig/c/common_characters_frequency_quotient.zig](../../../zig/c/common_characters_frequency_quotient.zig) |

## Verification

Verify all nine implementations with
`python3 benchmarks/verify_i64_array_bytes_output.py --algorithm common_characters_frequency_quotient`.
