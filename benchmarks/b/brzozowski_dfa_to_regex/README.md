# Brzozowski algebraic DFA-to-regex conversion

Convert the language of a complete deterministic finite automaton over the
binary alphabet `{0,1}` into a regular expression. The primary method writes
one language equation per state, then eliminates non-start state variables in
ascending state-ID order using Arden's lemma. This operation is separate from
the local [`brzozowski_dfa_minimization`](../brzozowski_dfa_minimization/README.md),
which reverses and determinizes an automaton to compute a minimal DFA.

## Contract

The `i64_array_bytes_output` input is
`[N,start_state,accepting_mask,(next_on_0,next_on_1)*N]`.
`N` is 1 through 3; IDs are `0..N-1`; bit `i` in `accepting_mask` marks state
`i` as accepting; and both transitions of every state must name an in-range
state. The valid input length is exactly `3+2*N` (at most 9 words); the parser
accepts up to 10 words so a trailing word can be rejected. Null or malformed
input returns `-1`.

The output is raw ASCII bytes without a terminator. Its grammar is:

- `#` denotes the empty language and `@` denotes epsilon.
- `0` and `1` are alphabet symbols.
- `|` is union, `.` is concatenation, and postfix `*` is Kleene star.
- Parentheses group compound expressions.

On success, the function returns the byte count. A null or undersized output
buffer returns `-2` and writes nothing. The maximum output is 270 bytes.

## Exact equation method and serialization

For each state `i`, the initial equation is
`R_i = union(a.R_delta(i,a) for a in {0,1})`, with `@` included in the union
when `i` is accepting. A missing transition coefficient is `#`.

For every non-start state `k`, in ascending state-ID order, let `A_kk` be its
self-loop coefficient. Replace each non-pivot equation with
`R_i = (A_ik.(A_kk)*.A_kj) | R_i` for each remaining state `j`, and include
`A_ik.(A_kk)*.B_k` in its constant term. Here `B_k` is the equation's current
constant. Then discard `k`'s equation. After all non-start states are
eliminated, solve the remaining start-state equation as
`(A_ss)*.B_s` using Arden's lemma.

Serialization applies these rules in every port:

- Empty-language and epsilon identities simplify union, concatenation, and
  star; identical union operands collapse.
- A nontrivial union sorts its two operands by ASCII byte order and emits
  `(left|right)`.
- A nontrivial concatenation emits `(left.right)`; a nontrivial star emits
  `(expression)*`.
- No associative flattening or further algebraic rewriting is done. This pins
  grouping and output bytes across ports.

With at most two non-start states, initial coefficient expressions are at
most 5 bytes and constants at most 1 byte. After one elimination, the bounds
are 32 and 24 bytes; after two, 140 and 124 bytes. The final start equation
therefore emits at most `143+124+3 = 270` bytes. There are `O(N^3)` regex
algebra operations for `N<=3`; their byte cost is linear in the bounded
operand/output sizes. The fixed workspace limit is 16,384 bytes.

The primary reference repeats coefficient/constant equation elimination. The
independent reference parses the result and checks language equivalence by
exploring the product of the input DFA and Brzozowski derivative states.
Workload outputs pin simple empty, universal, epsilon-only, and nontrivial
three-state languages; malformed frames and output-capacity errors are also
listed in [`workload.json`](workload.json).

Method sources: Brzozowski and Leiss, [“On Equations for Regular Languages,
Finite Automata, and Sequential Networks”](https://doi.org/10.1016/0304-3975(80)90069-9);
Arden's lemma; Brzozowski, [“Derivatives of Regular Expressions”](https://doi.org/10.1145/321239.321249).
The [pinned title index](https://github.com/acmeism/RosettaCodeData/blob/1d475861d7141ef2fafff293d9339f56e4b0f5db/popular-tasks)
was used only for discovery. No RosettaCode solutions, task prose, examples,
or tests were consulted or reused. That pinned index lists this title at score
16 (line 1608). See [RIGHTS.md](RIGHTS.md).

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/b/brzozowski_dfa_to_regex.c`](../../../c/b/brzozowski_dfa_to_regex.c) |
| C3 | [`c3/b/brzozowski_dfa_to_regex.c3`](../../../c3/b/brzozowski_dfa_to_regex.c3) |
| C++ | [`cpp/b/brzozowski_dfa_to_regex.cpp`](../../../cpp/b/brzozowski_dfa_to_regex.cpp) |
| Elisa | [`elisa/b/brzozowski_dfa_to_regex.elisa`](../../../elisa/b/brzozowski_dfa_to_regex.elisa) |
| Mojo | [`mojo/b/brzozowski_dfa_to_regex.mojo`](../../../mojo/b/brzozowski_dfa_to_regex.mojo) |
| Nim | [`nim/b/brzozowski_dfa_to_regex.nim`](../../../nim/b/brzozowski_dfa_to_regex.nim) |
| Odin | [`odin/b/brzozowski_dfa_to_regex.odin`](../../../odin/b/brzozowski_dfa_to_regex.odin) |
| Rust | [`rust/b/brzozowski_dfa_to_regex.rs`](../../../rust/b/brzozowski_dfa_to_regex.rs) |
| V | [`v/b/brzozowski_dfa_to_regex.v`](../../../v/b/brzozowski_dfa_to_regex.v) |
| Zig | [`zig/b/brzozowski_dfa_to_regex.zig`](../../../zig/b/brzozowski_dfa_to_regex.zig) |

These are source-only drafts. No programs, scripts, tests, checkers, builds,
compilers, profilers, or benchmarks were run.
