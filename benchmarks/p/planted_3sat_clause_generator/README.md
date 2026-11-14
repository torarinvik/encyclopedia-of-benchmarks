# Planted 3-SAT clause generator

Generate a fixed number of three-literal clauses satisfied by a supplied Boolean
assignment. The caller supplies the random choices, so results are deterministic.
For each clause, unrank a three-variable subset in lexicographic order and choose
one of the seven nonzero patterns indicating which literals are true under the
assignment. Repeated clauses are permitted. Independent uniform subset ranks and
patterns reproduce the fixed-clause-count planted model described by [Feige and
Vilenchik](https://www.wisdom.weizmann.ac.il/~feige/TechnicalReports/FeigeVilenchik.pdf).

Input is `[n,m,assignment[n],(subset_rank,truth_mask)*m]`, with `3<=n<=16`,
`0<=m<=32`, Boolean assignment entries, subset ranks in `[0,C(n,3))`, and
truth masks in `1..7`. Mask bit `i` selects whether literal `i` is true under
the planted assignment. Variables are ordered by increasing zero-based index;
positive literal `v+1` represents the variable and negative `-(v+1)` its
negation. Output consists of three little-endian i64 literals per clause, in
input tape order. A valid empty formula returns zero bytes even with null
output. Malformed or null input returns `-1`; null or short output for a
nonempty formula returns `-2`; errors write nothing. Maximum valid and
parseable input lengths are 82 and 83 words; maximum output is 768 bytes.

The primary uses lexicographic combinatorial unranking and takes O(m*n) time
with O(m) staged output space. An independent reference enumerates all triples
to check the rank mapping. The random distribution is conditional on the
caller supplying uniform independent choices; no pseudorandom generator or
distribution guarantee is included in the call. Existing planted-3SAT local
packages consume formulas and implement search, so neither duplicates this
generation operation. The cited paper is used for its model only; code,
contract, and fixtures are independently authored. No code has been run.
Drafts now exist in [C](../../../c/p/planted_3sat_clause_generator.c),
[C++](../../../cpp/p/planted_3sat_clause_generator.cpp),
[Rust](../../../rust/p/planted_3sat_clause_generator.rs), and
[Elisa](../../../elisa/p/planted_3sat_clause_generator.elisa). The Elisa draft
uses bounded views internally; all four remain uncompiled and untested.
[C3](../../../c3/p/planted_3sat_clause_generator.c3),
[Nim](../../../nim/p/planted_3sat_clause_generator.nim), and
[Zig](../../../zig/p/planted_3sat_clause_generator.zig) drafts are also present
and remain uncompiled and untested.
[Odin](../../../odin/p/planted_3sat_clause_generator.odin),
[V](../../../v/p/planted_3sat_clause_generator.v), and
[Mojo](../../../mojo/p/planted_3sat_clause_generator.mojo) drafts are also
present and remain uncompiled and untested.
Draft byte-output runner/verifier wiring and a static package checker are
present. The verifier source enumerates small assignments, subset ranks, and
truth masks, checks that each generated clause is satisfied, and specifies
maximum-frame and error cases. None of these checks has run.
The workload includes the final lexicographic subset, the valid empty/null
output case, invalid-input precedence, and null input at the parser limit.
