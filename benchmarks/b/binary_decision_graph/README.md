# Reduced ordered binary decision graph

This package builds a reduced ordered binary decision diagram from a Boolean truth table, following the Binary Decision Graph chapter, *Encyclopedia of Algorithms*, DOI [10.1007/978-1-4939-2864-4_48](https://doi.org/10.1007/978-1-4939-2864-4_48). The variable order is fixed: variable 0 is the most-significant truth-table bit. Equal low/high branches are eliminated, and identical `(variable,low,high)` nodes are shared. Terminals have IDs 0 and 1; nonterminals receive deterministic postorder IDs from 2 upward.

## Contract

Input is `[n, truth_table[2^n]]` with `1<=n<=6` and truth values 0 or 1. Truth-table rows use lexicographic assignments `00...0` through `11...1`. Output is `[root_id,node_count,(variable,low_id,high_id)*node_count]`, encoded as little-endian signed 64-bit values. There are at most 63 nonterminal nodes, so the maximum input length is 65 words and maximum output is 1,528 bytes. The function returns the output byte length, `-1` for malformed input, and `-2` for a null or short output buffer.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/b/binary_decision_graph.c`](../../../c/b/binary_decision_graph.c) |
| C3 | [`c3/b/binary_decision_graph.c3`](../../../c3/b/binary_decision_graph.c3) |
| C++ | [`cpp/b/binary_decision_graph.cpp`](../../../cpp/b/binary_decision_graph.cpp) |
| Elisa | [`elisa/b/binary_decision_graph.elisa`](../../../elisa/b/binary_decision_graph.elisa) |
| Nim | [`nim/b/binary_decision_graph.nim`](../../../nim/b/binary_decision_graph.nim) |
| Odin | [`odin/b/binary_decision_graph.odin`](../../../odin/b/binary_decision_graph.odin) |
| Rust | [`rust/b/binary_decision_graph.rs`](../../../rust/b/binary_decision_graph.rs) |
| V | [`v/b/binary_decision_graph.v`](../../../v/b/binary_decision_graph.v) |
| Zig | [`zig/b/binary_decision_graph.zig`](../../../zig/b/binary_decision_graph.zig) |

Primary oracle: [`binary_decision_graph_oracle.py`](../../binary_decision_graph_oracle.py). Independent verifier: [`binary_decision_graph_verifier_oracle.py`](../../binary_decision_graph_verifier_oracle.py).

## Attribution and rights

The ROBDD method is attributed to Adnan Aziz and Amit Prakash, “Binary Decision Graph,” *Encyclopedia of Algorithms* (2016), DOI 10.1007/978-1-4939-2864-4_48. No book prose, figures, or code are reproduced; all ports are independently written. Attribution does not grant rights to redistribute the book.
