# Finite-automaton string matching

This package ports the pinned Java `StringMatchFiniteAutomata.searchPattern` behavior over a bounded ASCII alphabet. It preprocesses a deterministic transition table, scans the text once, and returns every match position in ascending order, including overlapping matches.

## Contract

- Input is a signed i64 array laid out as `[text_length, pattern_length, text_ascii..., pattern_ascii...]`.
- Text length is 0 through 256; pattern length is 1 through 32. The exact input length is `2 + text_length + pattern_length`.
- Every text and pattern symbol is an ASCII code unit from 0 through 127. Matching is exact and case-sensitive.
- An empty pattern is excluded because the pinned source reports positions 1 through the text length as it consumes characters. A nonempty pattern longer than the text is valid and produces no matches.
- Output contains all match start offsets as little-endian signed i32 values. There is no count header; the return value is the byte count, so the match count is `return_value / 4`.
- Invalid input returns `-1` before output checks. A null output pointer returns `-2`, even when there are no matches. A non-null buffer with capacity 0 succeeds when there are no matches. A short buffer returns `-2` without partial writes.
- Maximum output is 1,024 bytes (256 positions).

The Java implementation creates transitions for all 65,536 UTF-16 code units. Each port builds a dense DFA over the contract's 128-symbol ASCII alphabet; this preserves all transitions reachable for valid inputs but does not reproduce the Java source's full-Unicode preprocessing cost. The maximum port table has `(32 + 1) * 128 = 4,224` entries. Workload measurements use one repetition per sample because the pinned implementation rebuilds its table on every call.

## Workload and oracle

[workload.json](workload.json) covers overlapping matches, exact and absent matches, empty text, patterns longer than the text, ASCII boundary symbols, maximum output, invalid inputs, null input and output, and short capacities. A null input is represented by an empty value list with a positive declared length so the ABI receives a null pointer without dereferencing it. The independent direct-slice oracle is [string_match_finite_automata_oracle.py](../../string_match_finite_automata_oracle.py).

Pinned source: [TheAlgorithms/Java StringMatchFiniteAutomata.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/StringMatchFiniteAutomata.java).

## Implementations

| Language | Source |
|---|---|
| C | [c/s/string_match_finite_automata.c](../../../c/s/string_match_finite_automata.c) |
| C3 | [c3/s/string_match_finite_automata.c3](../../../c3/s/string_match_finite_automata.c3) |
| C++ | [cpp/s/string_match_finite_automata.cpp](../../../cpp/s/string_match_finite_automata.cpp) |
| Elisa | [elisa/s/string_match_finite_automata.elisa](../../../elisa/s/string_match_finite_automata.elisa) |
| Nim | [nim/s/string_match_finite_automata.nim](../../../nim/s/string_match_finite_automata.nim) |
| Odin | [odin/s/string_match_finite_automata.odin](../../../odin/s/string_match_finite_automata.odin) |
| Rust | [rust/s/string_match_finite_automata.rs](../../../rust/s/string_match_finite_automata.rs) |
| V | [v/s/string_match_finite_automata.v](../../../v/s/string_match_finite_automata.v) |
| Zig | [zig/s/string_match_finite_automata.zig](../../../zig/s/string_match_finite_automata.zig) |

Build a selected port with:

    python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm string_match_finite_automata --language rust

Record with:

    python3 benchmarks/run_i64_array_bytes_output.py --algorithm string_match_finite_automata

Verify with:

    python3 benchmarks/verify_i64_array_bytes_output.py --algorithm string_match_finite_automata --languages rust
