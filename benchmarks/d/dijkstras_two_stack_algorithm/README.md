# Dijkstra's two-stack expression evaluation

This algorithm evaluates a fully parenthesized infix arithmetic expression with separate operand and operator stacks. It pushes single-digit operands and operators while scanning left to right, then applies the pending operation whenever it reads a closing parenthesis. Despite the name, this is an expression-evaluation algorithm, not graph shortest paths.

## Contract

Input is an ASCII byte sequence encoded as signed 64-bit integer values. A valid expression follows `expr := digit | '(' expr operator expr ')'`, where `digit` is `0` through `9` and `operator` is `+`, `-`, `*`, or `/`. Division must be exact and nonzero. Every intermediate and final result must fit `[-1,000,000,000, 1,000,000,000]`. Inputs contain at most 511 bytes. The function returns the integer result for valid expressions; checked out-of-domain arithmetic returns `-1,000,000,001`.

The bound permits fixed operand and operator stacks, so all nine implementations use O(n) time and O(n) stack storage without platform-specific instructions.

## Reproduce

```sh
python3 benchmarks/build_abi.py --family i64_array_scalar --algorithm dijkstras_two_stack_algorithm --language c
python3 benchmarks/run_i64_array_scalar.py --algorithm dijkstras_two_stack_algorithm
python3 benchmarks/verify_i64_array_scalar.py --algorithms dijkstras_two_stack_algorithm
```

## Implementations

| Language | Source |
| --- | --- |
| C | [`c/d/dijkstras_two_stack_algorithm.c`](../../../c/d/dijkstras_two_stack_algorithm.c) |
| C3 | [`c3/d/dijkstras_two_stack_algorithm.c3`](../../../c3/d/dijkstras_two_stack_algorithm.c3) |
| C++ | [`cpp/d/dijkstras_two_stack_algorithm.cpp`](../../../cpp/d/dijkstras_two_stack_algorithm.cpp) |
| Elisa | [`elisa/d/dijkstras_two_stack_algorithm.elisa`](../../../elisa/d/dijkstras_two_stack_algorithm.elisa) |
| Nim | [`nim/d/dijkstras_two_stack_algorithm.nim`](../../../nim/d/dijkstras_two_stack_algorithm.nim) |
| Odin | [`odin/d/dijkstras_two_stack_algorithm.odin`](../../../odin/d/dijkstras_two_stack_algorithm.odin) |
| Rust | [`rust/d/dijkstras_two_stack_algorithm.rs`](../../../rust/d/dijkstras_two_stack_algorithm.rs) |
| V | [`v/d/dijkstras_two_stack_algorithm.v`](../../../v/d/dijkstras_two_stack_algorithm.v) |
| Zig | [`zig/d/dijkstras_two_stack_algorithm.zig`](../../../zig/d/dijkstras_two_stack_algorithm.zig) |

## TheAlgorithms reference

- [Python `dijkstras_two_stack_algorithm.py`](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/dijkstras_two_stack_algorithm.py)
