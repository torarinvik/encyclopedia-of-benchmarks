# Pushdown Automaton

This benchmark adapts the pinned [TheAlgorithms/Jupyter `Pushdown_Automata_Implementation.ipynb`](https://github.com/TheAlgorithms/Jupyter/blob/ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9/Automaton/Pushdown_Automata_Implementation.ipynb).

## Contract

- ABI: `i64_array_scalar`, with packed input `[byte_len, ASCII byte values...]`.
- `byte_len` is in `0..=256`, the array contains exactly `byte_len + 1` values, and each payload value must be ASCII `0`, `1`, or `2` (`48`, `49`, or `50`). The maximum packed input length is 257 values.
- Return `1` exactly when the nonempty byte string has the form `(1|2)^n 0^n` for some `n >= 1`; return `0` for any other well-framed string in the alphabet. The empty string and odd-length strings are valid rejects. Return `-1` for malformed framing, an out-of-range byte length, a non-i64 input value, or a payload byte outside the alphabet.
- The source pushes the first-half `1`/`2` symbols and pops for each second-half `0`. It does not compare the pushed symbols with anything when popping; the accepted condition is equal counts with the two required phases.
- The notebook's displayed input `123456` is outside the declared alphabet. The benchmark applies the invalid-input sentinel to it rather than treating it as an in-alphabet reject.

The independent oracle is [`benchmarks/pushdown_automaton_oracle.py`](../../pushdown_automaton_oracle.py). The workload includes the notebook demonstration, source-shaped accepts and rejects, empty and odd strings, maximum-length cases, malformed framing, out-of-range counts, and out-of-alphabet bytes.

## Pinned source

The source is `TheAlgorithms/Jupyter` commit `ebf48b9d0373ae4caccd1d2fad54ad173dbac9e9`, notebook `Automaton/Pushdown_Automata_Implementation.ipynb`. Its stack pop retains the bottom marker, and its final-state check accepts only after the second phase empties all pushed symbols.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/pushdown_automaton.c`](../../../c/p/pushdown_automaton.c) |
| C3 | [`c3/p/pushdown_automaton.c3`](../../../c3/p/pushdown_automaton.c3) |
| C++ | [`cpp/p/pushdown_automaton.cpp`](../../../cpp/p/pushdown_automaton.cpp) |
| Elisa | [`elisa/p/pushdown_automaton.elisa`](../../../elisa/p/pushdown_automaton.elisa) |
| Nim | [`nim/p/pushdown_automaton.nim`](../../../nim/p/pushdown_automaton.nim) |
| Odin | [`odin/p/pushdown_automaton.odin`](../../../odin/p/pushdown_automaton.odin) |
| Rust | [`rust/p/pushdown_automaton.rs`](../../../rust/p/pushdown_automaton.rs) |
| V | [`v/p/pushdown_automaton.v`](../../../v/p/pushdown_automaton.v) |
| Zig | [`zig/p/pushdown_automaton.zig`](../../../zig/p/pushdown_automaton.zig) |
