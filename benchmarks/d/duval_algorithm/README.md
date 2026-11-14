# Duval Lyndon Factorization

Factor an ASCII sequence into its standard nonincreasing sequence of Lyndon words using Duval's linear-time algorithm. The contract preserves the Rust source's factor boundaries while encoding each factor as a length word to avoid allocating or returning concatenated text.

## Contract

- Input is 0 to 4,096 signed 64-bit ASCII codepoints in the range 0 through 127.
- Output is one unsigned 32-bit little-endian factor length for each Lyndon factor, in source order. Applying the lengths consecutively to the original input reconstructs the vector of factor strings.
- The function returns the factor count. Empty input returns zero factors and no bytes.
- A null input is accepted only for zero length. Invalid length, nonempty null input, or invalid codepoints return -1. For a nonempty result, a null output or insufficient capacity returns -2 before output is written. An empty result accepts a null output.
- The algorithm uses O(n) time; the output buffer holds O(n) factor lengths.

The pinned Rust source returns a vector of factor strings. This benchmark narrows input to ASCII and changes only the output representation. The separate duval candidate from C++ finds a least cyclic rotation index and is not the same operation.

## Workload

[workload.json](workload.json) covers the pinned Rust examples, empty/single-character input, repeated symbols, monotone and mixed sequences, invalid codepoints, and short output capacity.

## Implementations

| Language | Source |
| --- | --- |
| C | [c/d/duval_algorithm.c](../../../c/d/duval_algorithm.c) |
| C3 | [c3/d/duval_algorithm.c3](../../../c3/d/duval_algorithm.c3) |
| C++ | [cpp/d/duval_algorithm.cpp](../../../cpp/d/duval_algorithm.cpp) |
| Elisa | [elisa/d/duval_algorithm.elisa](../../../elisa/d/duval_algorithm.elisa) |
| Mojo | [mojo/d/duval_algorithm.mojo](../../../mojo/d/duval_algorithm.mojo) (draft, unverified) |
| Nim | [nim/d/duval_algorithm.nim](../../../nim/d/duval_algorithm.nim) |
| Odin | [odin/d/duval_algorithm.odin](../../../odin/d/duval_algorithm.odin) |
| Rust | [rust/d/duval_algorithm.rs](../../../rust/d/duval_algorithm.rs) |
| V | [v/d/duval_algorithm.v](../../../v/d/duval_algorithm.v) |
| Zig | [zig/d/duval_algorithm.zig](../../../zig/d/duval_algorithm.zig) |

## Upstream reference

- [TheAlgorithms/Rust duval_algorithm.rs](https://github.com/TheAlgorithms/Rust/blob/fed66cb0c74c4a939ec5163648458a8c2b46fd4c/src/string/duval_algorithm.rs)
- [TheAlgorithms/Java LyndonFactorization.java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/strings/LyndonFactorization.java) describes the same factorization scan, formerly represented by the separate `lyndon_factorization` profile.

The shared byte-output runner contains the Duval factorization recurrence. The byte-output verifier source registers this profile and specifies direct-reference comparisons on short inputs, a 4096-item boundary case, capacity errors, and invalid characters. This registration and its checks are unexecuted. The narrower duplicate `lyndon_factorization` profile was removed.

An independently structured [small-input reference](independent_oracle.py) identifies Lyndon prefixes using direct suffix comparisons. It is limited to 16 items to keep its intentionally expensive search bounded. The verifier source uses it to cross-check short binary-alphabet sequences; these checks have not been executed.

The reference follows the longest-Lyndon-prefix characterization of the first factor; see [Perrin's words and automata lecture](https://www-igm.univ-mlv.fr/~perrin/Enseignement/Master2015-16/Cours1/lecture1.pdf). It is independently authored and uses no source fixtures.
