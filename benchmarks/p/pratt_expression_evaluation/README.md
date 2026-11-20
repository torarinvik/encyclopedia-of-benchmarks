# Pratt top-down operator-precedence expression evaluation

This bounded profile evaluates a pretokenized integer expression using
Pratt's recursive binding-power method. It covers prefix and infix uses of
minus, multiplication, addition and subtraction, and grouped subexpressions.

## Contract

The ABI is `i64_array_scalar`; the package and exported symbol are
`pratt_expression_evaluation`. Input is
`[token_count,(kind,payload)*token_count]`, with `1..15` token pairs. Kind `1`
is a decimal digit literal with payload `0..9`; kinds `2`, `3`, and `4` are
`+`, `-`, and `*`; kinds `5` and `6` are opening and closing parentheses. All
operator payloads must be zero. Unary minus is the only prefix operator; unary
plus and implicit multiplication are invalid.

Multiplication binds above addition and subtraction. Binary operators are
left-associative. Unary negation binds above multiplication. Parentheses may
group a nonempty expression. The return value is the exact signed-i64 result.
Malformed framing, tokens, or expressions return `INT64_MIN`, which is outside
the valid result range. A valid expression has at most eight literal leaves;
by induction, each subtree with `m` leaves has magnitude at most `18^m`, so
all results and intermediates fit i64. Maximum valid and parseable input
lengths are 31 and 32 i64 words. The parser takes O(token_count) time and
O(token_count) recursive stack space, with at most 16 active calls.

## Algorithms and distinction

The primary parser handles the first token as a prefix form, then repeatedly
consumes infix operators whose left binding power meets the current minimum.
For a left-associative operator, the right expression uses the next greater
minimum; prefix minus parses with a binding power above multiplication. A
parenthesized form parses a full subexpression and consumes its matching
close token. This is Pratt's top-down operator-precedence method, described in
the original [1973 paper](https://tdop.github.io/) and its
[ACM record](https://doi.org/10.1145/512927.512931).

The independent reference converts tokens with shunting-yard operator/value
stacks and evaluates the resulting postfix sequence. The local
[`shunting_yard`](../../s/shunting_yard/README.md) evaluates a binary
floating-point character expression with an operator stack; this profile
instead measures recursive binding-power parsing over an integer token
stream, including unary negation and parentheses. The separate postfix
benchmarks consume an already-postfixed stream and do not parse infix syntax.

## Sources and rights

Vaughan R. Pratt, [“Top Down Operator Precedence”](https://tdop.github.io/),
POPL 1973, [DOI 10.1145/512927.512931](https://doi.org/10.1145/512927.512931),
is the algorithm reference. The bounded grammar, workload, implementations,
references, and prose are independently authored. No source code, task text,
examples, tests, or submissions are copied. See [`RIGHTS.md`](RIGHTS.md).

[`workload.json`](workload.json) contains original token frames and hand-derived
results. The static workload and inventory helpers are included but were not
run. The package is registered in the shared `i64_array_scalar` runner and
verifier.

## Native ports

| Language | Source |
| --- | --- |
| C | [`c/p/pratt_expression_evaluation.c`](../../../c/p/pratt_expression_evaluation.c) |
| C3 | [`c3/p/pratt_expression_evaluation.c3`](../../../c3/p/pratt_expression_evaluation.c3) |
| C++ | [`cpp/p/pratt_expression_evaluation.cpp`](../../../cpp/p/pratt_expression_evaluation.cpp) |
| Elisa | [`elisa/p/pratt_expression_evaluation.elisa`](../../../elisa/p/pratt_expression_evaluation.elisa) |
| Mojo | [`mojo/p/pratt_expression_evaluation.mojo`](../../../mojo/p/pratt_expression_evaluation.mojo) |
| Nim | [`nim/p/pratt_expression_evaluation.nim`](../../../nim/p/pratt_expression_evaluation.nim) |
| Odin | [`odin/p/pratt_expression_evaluation.odin`](../../../odin/p/pratt_expression_evaluation.odin) |
| Rust | [`rust/p/pratt_expression_evaluation.rs`](../../../rust/p/pratt_expression_evaluation.rs) |
| V | [`v/p/pratt_expression_evaluation.v`](../../../v/p/pratt_expression_evaluation.v) |
| Zig | [`zig/p/pratt_expression_evaluation.zig`](../../../zig/p/pratt_expression_evaluation.zig) |
