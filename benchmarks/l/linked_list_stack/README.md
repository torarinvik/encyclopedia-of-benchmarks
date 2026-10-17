# Linked-list stack operation trace

This benchmark follows the shared stack behavior in the pinned Dart and TypeScript implementations. Each call creates an empty stack. Push links an item at the head; pop removes and returns the head; size and `isEmpty` query the current stack. The TypeScript class also exposes `top`, but that method is outside the common benchmark interface.

## Contract

- The ABI is `i64_array_bytes_output`. Input is `[operation_count, opcode, push_value_if_needed, ...]`, with 0–64 operations and exact framing. Opcode `0` pushes a signed-i32 value, `1` pops, `2` returns the size, and `3` returns whether the stack is empty. Push values are carried in signed-i64 words and must fit signed i32.
- The stack begins empty and has a 64-item benchmark limit. The TypeScript port must construct the source class with `limit: 64` or enforce that same limit in its adapter. A push past the limit is invalid. An empty pop is also invalid for this ABI, although the Dart method itself prints and returns null; traces cannot continue through an empty pop.
- Push emits no query record. Each pop, size, or emptiness query emits one `[kind, value]` pair. Kind `1` is a popped value, kind `2` is the current size, and kind `3` is `isEmpty` (`1` for empty and `0` otherwise). The output is `[query_count, kind, value, ...]`, encoded as little-endian signed-i32 words.
- Valid output is at least 4 bytes and at most 516 bytes. The empty trace `[0]` returns `[0]` in 4 bytes. Invalid or null input returns `-1` before output-buffer checks. A null output pointer or insufficient capacity returns `-2` without writing any output.

The workload contains semantic traces and ABI boundary cases in [workload.json](workload.json). Its independent list-based oracle is [benchmarks/linked_list_stack_oracle.py](../../linked_list_stack_oracle.py).

Pinned sources: [TheAlgorithms/Dart `Linked_List_Stack.dart`](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Stack/Linked_List_Stack.dart) and [TheAlgorithms/TypeScript `linked_list_stack.ts`](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/stack/linked_list_stack.ts).

## Reproduce

~~~sh
python3 benchmarks/build_abi.py --family i64_array_bytes_output --algorithm linked_list_stack --language rust
python3 benchmarks/run_i64_array_bytes_output.py --algorithm linked_list_stack
python3 benchmarks/verify_i64_array_bytes_output.py --algorithm linked_list_stack --languages rust
~~~

## Language ports

| Language | Source |
| --- | --- |
| C | [c/l/linked_list_stack.c](../../../c/l/linked_list_stack.c) |
| C3 | [c3/l/linked_list_stack.c3](../../../c3/l/linked_list_stack.c3) |
| C++ | [cpp/l/linked_list_stack.cpp](../../../cpp/l/linked_list_stack.cpp) |
| Elisa | [elisa/l/linked_list_stack.elisa](../../../elisa/l/linked_list_stack.elisa) |
| Nim | [nim/l/linked_list_stack.nim](../../../nim/l/linked_list_stack.nim) |
| Odin | [odin/l/linked_list_stack.odin](../../../odin/l/linked_list_stack.odin) |
| Rust | [rust/l/linked_list_stack.rs](../../../rust/l/linked_list_stack.rs) |
| V | [v/l/linked_list_stack.v](../../../v/l/linked_list_stack.v) |
| Zig | [zig/l/linked_list_stack.zig](../../../zig/l/linked_list_stack.zig) |
