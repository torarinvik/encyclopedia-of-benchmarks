# Suffix automaton

This package exposes the query behavior of the pinned Python
[`SuffixAutomaton`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/strings/suffix_automaton.py).
The source builds an online automaton for a nonempty text and supports
substring membership, occurrence counts, and distinct-substring counts.

## Contract

The `i64_array_bytes_output` input is
`[text_length, text_bytes..., query_count, (opcode, pattern_length, pattern_bytes...)*]`.
Text length is 1–256, query count is 0–128, and text and pattern bytes are
ASCII values 0–127. There are exactly 1–256 text bytes. Opcodes are:

- `0`: `contains(pattern)`; pattern length may be 0–256.
- `1`: `count_occurrences(pattern)`; pattern length may be 0–256.
- `2`: `count_distinct_substrings()`; pattern length must be zero.

For every query the packet includes the opcode and pattern length; opcode 2
uses a zero pattern length and no pattern bytes. The maximum valid packet is
33,282 signed 64-bit words; one more word is parseable to reject trailing data.

Results are emitted in query order. Each record is nine bytes: the one-byte
query opcode followed by the result as a little-endian signed 64-bit integer.
Boolean membership results are 0 or 1. Occurrence counts include overlaps.
The source-specific empty-pattern behavior is preserved: `contains("")` is
true, and `count_occurrences("")` returns the text length (not length plus
one). Distinct-substring counts exclude the empty substring.

The return value and output capacity are measured in bytes. Invalid input
returns `-1` before output checks. A null output pointer returns `-2`, even
when the query count is zero; a nonnull capacity-zero buffer succeeds for a
zero-query packet. Otherwise, capacity below nine bytes per query returns
`-2`. Errors write nothing. The maximum output is 128 records, or 1,152
bytes.

The independent oracle uses direct substring operations rather than an
automaton. The workload is in [`workload.json`](workload.json), and the oracle
is [`benchmarks/suffix_automaton_oracle.py`](../../suffix_automaton_oracle.py).

## Source

The source is pinned to TheAlgorithms/Python commit
`e1a2a8b016001309a73d5fec4818c35cca139795`, path
`strings/suffix_automaton.py`, class `SuffixAutomaton`.

## Language ports

| Language | Source |
|---|---|
| C | [`c/s/suffix_automaton.c`](../../../c/s/suffix_automaton.c) |
| C3 | [`c3/s/suffix_automaton.c3`](../../../c3/s/suffix_automaton.c3) |
| C++ | [`cpp/s/suffix_automaton.cpp`](../../../cpp/s/suffix_automaton.cpp) |
| Elisa | [`elisa/s/suffix_automaton.elisa`](../../../elisa/s/suffix_automaton.elisa) |
| Nim | [`nim/s/suffix_automaton.nim`](../../../nim/s/suffix_automaton.nim) |
| Odin | [`odin/s/suffix_automaton.odin`](../../../odin/s/suffix_automaton.odin) |
| Rust | [`rust/s/suffix_automaton.rs`](../../../rust/s/suffix_automaton.rs) |
| V | [`v/s/suffix_automaton.v`](../../../v/s/suffix_automaton.v) |
| Zig | [`zig/s/suffix_automaton.zig`](../../../zig/s/suffix_automaton.zig) |

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm suffix_automaton --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm suffix_automaton
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm suffix_automaton --languages rust
~~~
