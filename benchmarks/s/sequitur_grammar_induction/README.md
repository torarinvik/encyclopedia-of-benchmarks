# Sequitur grammar induction

This package benchmarks a bounded, deterministic profile of the online
SEQUITUR grammar-induction algorithm. It appends byte-valued terminals to a
start rule and repairs repeated adjacent-symbol pairs (digram uniqueness) and
single-use nonterminal rules (rule utility). Nonterminals can appear inside
other rules, so repairs expose longer repeated phrases hierarchically.

The input is `[n, byte_0, ..., byte_(n-1)]`, with `0 <= n <= 64` and each byte
in `0..255`. The frame must contain exactly `n+1` words. The maximum valid
frame is 65 words; a 66-word parseable frame is used to reject trailing data.
The scalar result is `1000 * live_nonstart_rule_count + total_live_rhs_symbol_count`.
Malformed or null input returns `-1`; the published result bound is 64,064.

SEQUITUR can produce more than one valid grammar for the same input. This
bounded profile makes the tie policy explicit: scan live rules by ascending
rule ID and digram position, then choose the first lexicographic pair of
non-overlapping occurrences; if an existing two-symbol rule matches, reuse
the lowest-ID such rule and replace the first duplicate occurrence outside
that rule. Otherwise create a new rule and replace both selected occurrences.
After each repair, discard any zero-use rule and inline the lowest-ID non-start
rule referenced exactly once, restarting the cleanup scan after each deletion.
Overlapping occurrences do not trigger a repair, so `aaa` produces no rule.
Rule IDs are assigned in
creation order and are never reused. These choices make every port deterministic.

The primary reference follows the paper's online repair constraints. The
independent reference rebuilds an occurrence table from all active rule bodies
at each normalization step. Both compute the same scalar summary while using
different duplicate-discovery structures. The ports use bounded full-grammar
rescans rather than the paper's linear-time hash-index implementation. Their
fixed workspace has 256 rule IDs and 64 symbol slots per rule. The fixed
256 rule-ID slots cover the fewer-than-`2n` rule creations
established by the paper's amortized operation bound at `n <= 64`. The 64,064
output bound follows from at most 64 live RHS symbols and at most 64 active
non-start rules, since every live non-start rule has at least one RHS symbol.
Unary rules can arise when a pair in a two-symbol rule is replaced by an
existing nonterminal. The repeated full-grammar scans have a conservative
O(n^3) bound for this fixed profile; this package does not claim the paper's
linear-time hash-index implementation.

The algorithm is distinct from the suite's byte-level BPE tokenizer: BPE
selects the most frequent adjacent pair at each merge, while this profile
maintains grammar-wide digram uniqueness and rule utility incrementally.
It also differs from suffix indexes, automata, and matching packages because
it constructs a hierarchical grammar rather than an index or recognizer.

The method is described in Nevill-Manning and Witten's [1997 paper](https://ml.cms.waikato.ac.nz/publications/1997/NM-IHW-Hierarch97.pdf)
and Nevill-Manning's [1996 thesis](https://ml.cms.waikato.ac.nz/publications/1996/NevMan-Thesis.pdf).
Only algorithmic ideas are used. The contract, tie policy, implementations,
references, and fixtures are independently authored.

Language ports: [C](../../../c/s/sequitur_grammar_induction.c),
[C3](../../../c3/s/sequitur_grammar_induction.c3),
[C++](../../../cpp/s/sequitur_grammar_induction.cpp),
[Elisa](../../../elisa/s/sequitur_grammar_induction.elisa),
[Mojo](../../../mojo/s/sequitur_grammar_induction.mojo),
[Nim](../../../nim/s/sequitur_grammar_induction.nim),
[Odin](../../../odin/s/sequitur_grammar_induction.odin),
[Rust](../../../rust/s/sequitur_grammar_induction.rs),
[V](../../../v/s/sequitur_grammar_induction.v), and
[Zig](../../../zig/s/sequitur_grammar_induction.zig).

No program, test, build, compiler, checker, or benchmark was run while preparing
this package.
