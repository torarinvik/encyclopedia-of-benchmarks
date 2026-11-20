# Trie-built generalized suffix automaton

Input is `[S,(length,string_symbols...)*S]` for 2..8 strings over the four-symbol alphabet `0..3`. Each string has at most 8 symbols and the total is at most 24. The result is the number of distinct nonempty substrings appearing in the union of the strings. Empty strings are allowed. Malformed input returns `-1`.

The primary builds a trie, processes its edges in breadth-first order, and inserts each trie child into a shared suffix automaton. When a transition requires a clone, the clone receives only already-built automaton transitions. The result is `sum(len[v] - len[link[v]])` over non-root states. Dense transition rows give `O(V * alphabet_size)` construction time and storage, where `V` is the trie node count and the alphabet has four symbols. The independent reference enumerates all substrings into a set.

This is distinct from a single-text suffix automaton and from pairwise longest-common-substring automata: it builds one automaton for a set of strings and counts the union of their substring languages. The method is described in the [OI Wiki generalized suffix automaton article](https://oi-wiki.org/string/general-sam/). Only the algorithmic description was used; this package is independently implemented.

| Language | Port |
|---|---|
| C | [c/g/generalized_suffix_automaton_union.c](../../../c/g/generalized_suffix_automaton_union.c) |
| C3 | [c3/g/generalized_suffix_automaton_union.c3](../../../c3/g/generalized_suffix_automaton_union.c3) |
| C++ | [cpp/g/generalized_suffix_automaton_union.cpp](../../../cpp/g/generalized_suffix_automaton_union.cpp) |
| Elisa | [elisa/g/generalized_suffix_automaton_union.elisa](../../../elisa/g/generalized_suffix_automaton_union.elisa) |
| Mojo | [mojo/g/generalized_suffix_automaton_union.mojo](../../../mojo/g/generalized_suffix_automaton_union.mojo) |
| Nim | [nim/g/generalized_suffix_automaton_union.nim](../../../nim/g/generalized_suffix_automaton_union.nim) |
| Odin | [odin/g/generalized_suffix_automaton_union.odin](../../../odin/g/generalized_suffix_automaton_union.odin) |
| Rust | [rust/g/generalized_suffix_automaton_union.rs](../../../rust/g/generalized_suffix_automaton_union.rs) |
| V | [v/g/generalized_suffix_automaton_union.v](../../../v/g/generalized_suffix_automaton_union.v) |
| Zig | [zig/g/generalized_suffix_automaton_union.zig](../../../zig/g/generalized_suffix_automaton_union.zig) |
