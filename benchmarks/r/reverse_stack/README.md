# Reverse stack

This benchmark ports the recursive stack reversal in the pinned [C# source](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/Algorithms/Stack/ReverseStack.cs) and [Java source](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/stacks/ReverseStack.java). Each source pops the top item, recursively reverses the remaining stack, and inserts the popped item at the bottom.

## Contract

- ABI: `i64_array_bytes_output`. Input is `[count, item_0, ..., item_(count-1)]`, where the items are listed from the stack bottom to its top. The exact input length is `count + 1`.
- `count` is in `0..16`; each item is a signed integer in `[-1,000,000,1,000,000]`. The small count bound limits recursive depth and the source algorithm's quadratic work.
- The source is given a stack populated by pushing the items in the listed order. After reversal, serialize the stack from bottom to top as `[count, reversed_items...]`, with every value encoded as a signed 64-bit little-endian integer. The count prefix makes an empty stack's result explicit.
- Success returns the output byte count, `8 * (count + 1)`. Invalid input, including a null input pointer, returns `-1`. A null output pointer or insufficient output capacity returns `-2`; input validation takes precedence. Failures do not write output. Maximum output and workspace are 136 bytes.

The C# source documents a null exception but dereferences `stack.Count`; the Java source explicitly throws `IllegalArgumentException` for null. This benchmark maps a null input pointer to the common invalid-input result. The [independent oracle](../../reverse_stack_oracle.py) and [`workload.json`](workload.json) cover empty, singleton, duplicate, signed, and maximum-size stacks plus malformed inputs.

## Build and verify

```sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm reverse_stack --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm reverse_stack
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm reverse_stack --languages rust
```

## Implementations

| Language | Port |
|---|---|
| C | [`c/r/reverse_stack.c`](../../../c/r/reverse_stack.c) |
| C3 | [`c3/r/reverse_stack.c3`](../../../c3/r/reverse_stack.c3) |
| C++ | [`cpp/r/reverse_stack.cpp`](../../../cpp/r/reverse_stack.cpp) |
| Elisa | [`elisa/r/reverse_stack.elisa`](../../../elisa/r/reverse_stack.elisa) |
| Nim | [`nim/r/reverse_stack.nim`](../../../nim/r/reverse_stack.nim) |
| Odin | [`odin/r/reverse_stack.odin`](../../../odin/r/reverse_stack.odin) |
| Rust | [`rust/r/reverse_stack.rs`](../../../rust/r/reverse_stack.rs) |
| V | [`v/r/reverse_stack.v`](../../../v/r/reverse_stack.v) |
| Zig | [`zig/r/reverse_stack.zig`](../../../zig/r/reverse_stack.zig) |
