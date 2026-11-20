# Balanced parenthesis successor

This profile computes the immediate lexicographic successor of one valid
single-type balanced-parenthesis sequence. It keeps the unchanged prefix,
changes the rightmost feasible `(` to `)`, and rebuilds the remaining suffix in
the smallest balanced order. The operation takes linear time and uses bounded
linear storage for the output.

## Contract

Input is `[pair_count,symbols...]`, with `1<=pair_count<=10` and exactly
`2*pair_count` symbols. Symbol `0` means `(` and symbol `1` means `)`. The
sequence must be balanced and every prefix must contain at least as many opens
as closes. On success, output bytes are the next sequence in ASCII, with
`(` = 40 and `)` = 41; the return value is the byte count. After the input is
validated, a null or undersized output returns `-2` without writing; the
required capacity is `2*pair_count`, even when the input is already the maximum
sequence. With adequate non-null output storage, that maximum sequence returns
`-3` and writes nothing. Malformed input returns `-1`. Maximum input and output
lengths are 21 signed 64-bit values and 20 bytes.

The primary follows the article's right-to-left successor scan. The independent
oracle exhaustively enumerates fixed-cardinality open-position sets in
lexicographic order and selects the sequence after the input. This is the
single-successor operation only; [`parentheses_generator`](../../p/parentheses_generator/README.md)
enumerates every Catalan word recursively, and is not the same computation.

Source: CP-Algorithms, [Balanced bracket sequences — finding the lexicographical
next balanced sequence](https://cp-algorithms.com/combinatorics/bracket_sequences.html#finding-the-lexicographical-next-balanced-sequence),
CC BY-SA 4.0. The article is used for the algorithm idea only; the bounded
contract, implementations, references, fixtures, and prose are clean-room.
See [RIGHTS.md](RIGHTS.md).

## Static inventory

[`verify_workload.py`](verify_workload.py) checks fixture/reference agreement,
metadata, required cases, and all ten exported source paths without compiling
or executing the ports.

| Language | Port |
|---|---|
| C | [`c/b/balanced_parenthesis_successor.c`](../../../c/b/balanced_parenthesis_successor.c) |
| C3 | [`c3/b/balanced_parenthesis_successor.c3`](../../../c3/b/balanced_parenthesis_successor.c3) |
| C++ | [`cpp/b/balanced_parenthesis_successor.cpp`](../../../cpp/b/balanced_parenthesis_successor.cpp) |
| Elisa | [`elisa/b/balanced_parenthesis_successor.elisa`](../../../elisa/b/balanced_parenthesis_successor.elisa) |
| Mojo | [`mojo/b/balanced_parenthesis_successor.mojo`](../../../mojo/b/balanced_parenthesis_successor.mojo) |
| Nim | [`nim/b/balanced_parenthesis_successor.nim`](../../../nim/b/balanced_parenthesis_successor.nim) |
| Odin | [`odin/b/balanced_parenthesis_successor.odin`](../../../odin/b/balanced_parenthesis_successor.odin) |
| Rust | [`rust/b/balanced_parenthesis_successor.rs`](../../../rust/b/balanced_parenthesis_successor.rs) |
| V | [`v/b/balanced_parenthesis_successor.v`](../../../v/b/balanced_parenthesis_successor.v) |
| Zig | [`zig/b/balanced_parenthesis_successor.zig`](../../../zig/b/balanced_parenthesis_successor.zig) |
