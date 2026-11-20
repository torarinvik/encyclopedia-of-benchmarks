# Markov normal string rewriting

This package interprets a bounded ordered Markov normal algorithm over a
finite alphabet. Each rewrite selects the first rule in priority order that
matches anywhere in the current word, replaces that rule's leftmost
occurrence, and restarts rule selection from the first rule. A final rule
halts immediately after its replacement. This is a rewrite-system interpreter,
distinct from probabilistic Markov-chain simulation and from one-pass string
replacement.

## Contract

ABI: `i64_array_bytes_output`; symbol: `markov_normal_string_rewriting`.
Input is `[rule_count,step_limit,word_length,word...,rule...]`, where each rule
is `[kind,lhs_length,rhs_length,lhs...,rhs...]`. `kind=0` is an ordinary
rewrite and `kind=1` is a final rewrite. Rules are listed in priority order;
left-hand sides are nonempty. The input allows 0–8 rules, a 0–32 rewrite cap,
an initial word of 0–48 symbols, and 0–25 alphabet symbols. Each side has at
most 8 symbols, and a replacement may be empty. The largest valid frame is
203 signed-i64 words; one additional parseable word is reserved for malformed
trailing-input cases.

The interpreter applies at most `step_limit` rewrites. After reaching that
limit, it reports the cap only if another rule is enabled; a word with no
matching rule reports normal halting. Applying a final rule reports final-rule
halting immediately. Intermediate words may contain up to 64 symbols. If a
rewrite would exceed that bound, the call returns `-3` without output bytes.

Successful output is the raw byte sequence
`[halt_code,rewrite_count,final_word_length,final_word_symbols...]`. Halt code
0 means no rule applies, 1 means a final rule was applied, and 2 means the
rewrite cap was reached while a rule remained enabled. The maximum output is
67 bytes. Invalid input returns `-1`; null output or insufficient capacity
returns `-2`. The full input frame is validated before output-capacity
handling. Error results write no output bytes.

## Complexity

Let `I` be the input word count, `R` the number of rules, `W` the maximum
intermediate word length, `M` the maximum left-hand-side length, and `T` the
rewrite limit. The priority-ordered primary takes
`O(I + (T+1)RWM + TW)` worst-case time: it scans rules and possible match
positions after each rewrite and once more to distinguish normal halting from
the step cap. The occurrence-enumerating independent reference selects the
lexicographically earliest `(rule_index,offset)` among all matches. Workspace
is `O(RM+W)` for fixed rule and word buffers; the caller-owned output buffer is
excluded. The native workspace cap is 4,096 bytes.

## Sources and provenance

The implementation follows Markov's ordered normal-algorithm rewrite model,
as described in A. A. Markov, “Theory of algorithms” ([publication record and
text](https://www.mathnet.ru/eng/im2534)) and the
[Encyclopedia of Mathematics entry on normal algorithms](https://encyclopediaofmath.org/wiki/Normal_algorithm).
The [RosettaGit task](https://rosettagit.org/tasks/execute-a-markov-algorithm/)
was used as a discovery lead only. No task code, wording, examples, or tests
were reused; the bounded frame, interpreter, and fixtures are clean-room work.
See [`RIGHTS.md`](RIGHTS.md).

The primary and structurally independent references are
[`primary_oracle.py`](primary_oracle.py) and
[`independent_oracle.py`](independent_oracle.py). See
[`workload.json`](workload.json), [`INVENTORY.md`](INVENTORY.md), and
[`INVENTORY.json`](INVENTORY.json).

| Language | Source |
|---|---|
| C | [`c/m/markov_normal_string_rewriting.c`](../../../c/m/markov_normal_string_rewriting.c) |
| C3 | [`c3/m/markov_normal_string_rewriting.c3`](../../../c3/m/markov_normal_string_rewriting.c3) |
| C++ | [`cpp/m/markov_normal_string_rewriting.cpp`](../../../cpp/m/markov_normal_string_rewriting.cpp) |
| Elisa | [`elisa/m/markov_normal_string_rewriting.elisa`](../../../elisa/m/markov_normal_string_rewriting.elisa) |
| Mojo | [`mojo/m/markov_normal_string_rewriting.mojo`](../../../mojo/m/markov_normal_string_rewriting.mojo) |
| Nim | [`nim/m/markov_normal_string_rewriting.nim`](../../../nim/m/markov_normal_string_rewriting.nim) |
| Odin | [`odin/m/markov_normal_string_rewriting.odin`](../../../odin/m/markov_normal_string_rewriting.odin) |
| Rust | [`rust/m/markov_normal_string_rewriting.rs`](../../../rust/m/markov_normal_string_rewriting.rs) |
| V | [`v/m/markov_normal_string_rewriting.v`](../../../v/m/markov_normal_string_rewriting.v) |
| Zig | [`zig/m/markov_normal_string_rewriting.zig`](../../../zig/m/markov_normal_string_rewriting.zig) |
