# Prefix expression evaluation

This benchmark ports the pinned Python module's active iterative `evaluate` function. It scans whitespace-separated tokens in reverse, pushes one-digit operands, and applies the four arithmetic operators using a stack.

## Contract

- Input is `[ASCII byte length, expression bytes...]`.
- Expressions contain single-digit operands (`0`–`9`) and `+`, `-`, `*`, `/`, separated by exactly one ASCII space. The maximum is 31 tokens.
- Division follows source stack-pop order; integer-looking inputs return a binary64 result.
- Malformed expressions and division by zero return `-1e300`.

The source also defines `evaluate_recursive`, which consumes a list of tokens and mutates it. The benchmark targets the iterative function used by the module's driver. Numeric intermediate bounds keep exact integer operations within binary64's exact range.

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/p/prefix_evaluation.c`](../../../c/p/prefix_evaluation.c) |
| C3 | [`c3/p/prefix_evaluation.c3`](../../../c3/p/prefix_evaluation.c3) |
| C++ | [`cpp/p/prefix_evaluation.cpp`](../../../cpp/p/prefix_evaluation.cpp) |
| Elisa | [`elisa/p/prefix_evaluation.elisa`](../../../elisa/p/prefix_evaluation.elisa) |
| Nim | [`nim/p/prefix_evaluation.nim`](../../../nim/p/prefix_evaluation.nim) |
| Odin | [`odin/p/prefix_evaluation.odin`](../../../odin/p/prefix_evaluation.odin) |
| Rust | [`rust/p/prefix_evaluation.rs`](../../../rust/p/prefix_evaluation.rs) |
| V | [`v/p/prefix_evaluation.v`](../../../v/p/prefix_evaluation.v) |
| Zig | [`zig/p/prefix_evaluation.zig`](../../../zig/p/prefix_evaluation.zig) |

## Workload and recording

[`workload.json`](workload.json) covers nested operations, fractional division, one operand, malformed stacks, and division by zero. The runtime oracle is [`prefix_evaluation_oracle.py`](../../prefix_evaluation_oracle.py); the float64-array runner validates expectations before recording.

## Pinned source

- [TheAlgorithms/Python `prefix_evaluation.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/prefix_evaluation.py)
