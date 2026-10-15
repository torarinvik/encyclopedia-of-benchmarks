# Duplicate Brackets

Detect redundant parentheses in an ASCII expression using the pinned Java source's stack scan. When a closing parenthesis is reached, an empty stack or an opening parenthesis on top means the pair contained no intervening expression content and the method returns `true`.

## Contract

- The signed 64-bit input packs `[length, byte_0, ..., byte_(length-1)]`.
- `length` is from 0 through 256, and the packed array must contain exactly `length + 1` values.
- Each expression byte must be printable ASCII, 32 through 126. Parentheses must be balanced.
- Return `1` when the source stack detects a redundant pair, `0` otherwise. Empty input returns `0`. Malformed, unbalanced, non-printable, or out-of-domain input returns `-1`.
- Balanced parentheses are a stated precondition of the Java method. The benchmark checks that precondition before applying the source's duplicate-pair scan.

## Workload

[`workload.json`](workload.json) covers expressions with no parentheses, ordinary grouping, empty groups, nested duplicate groups, and malformed packed inputs.

## Reviewed source

- [Java `DuplicateBrackets.java`](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/stacks/DuplicateBrackets.java) — pushes characters and, for each `)`, reports a duplicate if the stack is empty or its top is `(`; otherwise it removes characters through the matching opening parenthesis.

This checks for redundant grouping, not whether parentheses are balanced. It is distinct from `valid_parentheses` and `balanced_parentheses`, which check structural balance.

The shared `i64_array_scalar` runner first enforces the printable-ASCII and balanced-parenthesis preconditions, then checks the source stack rule.

## Implementations

The nine ports use the shared `i64_array_scalar` ABI. Their source files are in the `d` folder for each language. The source-backed oracle is implemented in `benchmarks/run_i64_array_scalar.py`.
