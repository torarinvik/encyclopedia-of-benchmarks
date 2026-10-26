# Approximate regular-expression matching over a bounded NFA

This package implements the layered edit-distance shortest-path core described in “Approximate Regular Expression Matching,” *Encyclopedia of Algorithms*, DOI [10.1007/978-1-4939-2864-4_22](https://doi.org/10.1007/978-1-4939-2864-4_22). It accepts a bounded literal-transition NFA directly, avoiding a regex parser while retaining the core state/text-layer computation. The NFA can be nondeterministic and cyclic; each transition consumes one ASCII byte.

## Contract

Input is `[state_count,transition_count,text_length,max_errors,start_state,accept_state,(src,dst,label)*,text_bytes...]`. There are 2–8 states, 1–16 distinct transitions, 0–12 text bytes, and an error threshold 0–3. Transition labels and text bytes are in 1–127. The start and accept states differ. Unit-cost insertion traverses an NFA edge without consuming text, deletion consumes text without changing state, and match/substitution consumes one byte and one edge. A free start is made available at each text boundary. The result contains one byte for each text ending position; a position is 1 when a nonempty text substring ending there is within the threshold of some accepted NFA path. Empty-only matches are excluded.

The function returns the text length on success, `-1` for malformed input, and `-2` for a null or short output buffer. All framing, automaton, byte, and capacity checks finish before output is written. Regex parsing, Thompson-NFA construction, weighted edit costs, and reporting a best alignment are outside this bounded profile.

The primary oracle uses layered dynamic programming with same-layer insertion closure. The independent verifier runs 0-1 shortest-path searches over the automaton/text product separately for each possible substring start.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/a/approximate_regex_matching.c`](../../../c/a/approximate_regex_matching.c) |
| C3 | [`c3/a/approximate_regex_matching.c3`](../../../c3/a/approximate_regex_matching.c3) |
| C++ | [`cpp/a/approximate_regex_matching.cpp`](../../../cpp/a/approximate_regex_matching.cpp) |
| Elisa | [`elisa/a/approximate_regex_matching.elisa`](../../../elisa/a/approximate_regex_matching.elisa) |
| Nim | [`nim/a/approximate_regex_matching.nim`](../../../nim/a/approximate_regex_matching.nim) |
| Odin | [`odin/a/approximate_regex_matching.odin`](../../../odin/a/approximate_regex_matching.odin) |
| Rust | [`rust/a/approximate_regex_matching.rs`](../../../rust/a/approximate_regex_matching.rs) |
| V | [`v/a/approximate_regex_matching.v`](../../../v/a/approximate_regex_matching.v) |
| Zig | [`zig/a/approximate_regex_matching.zig`](../../../zig/a/approximate_regex_matching.zig) |

Primary oracle: [`approximate_regex_matching_oracle.py`](../../approximate_regex_matching_oracle.py). Independent verifier: [`approximate_regex_matching_verifier_oracle.py`](../../approximate_regex_matching_verifier_oracle.py).

## Attribution and rights

The algorithmic idea is attributed to Gonzalo Navarro, “Approximate Regular Expression Matching,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_22. The chapter is used only to identify the algorithm and its shortest-path formulation. No book prose, figures, or source code are reproduced; the implementations are independently written. This attribution does not grant rights to redistribute the book.
