# Stack operation trace

The pinned inventory finds stack implementations in 12 TheAlgorithms repositories. The names commonly expose `push`, `pop`, `peek`/`top`, and an empty check, but the underlying storage differs: the C examples include growing-array and linked-list variants, C++ uses a linked representation, Elixir uses an immutable list, and Zig uses a linked stack. The shared benchmark therefore measures the same bounded LIFO operations through an array-backed implementation in each target language; it does not claim to compare the upstream storage strategies directly.

## Contract

The `i64_array_scalar` function accepts zero to 1,024 signed 64-bit values encoded as `[opcode, payload]` pairs, for at most 512 operations. Opcodes are:

- `0`: push a payload from -1,000,000 through 1,000,000
- `1`: pop, with payload zero
- `2`: peek at the top, with payload zero
- `3`: report whether the stack is empty, with payload zero

The stack capacity is 256. Odd-length input, unknown operations, out-of-range push values, nonzero payloads for operations 1–3, underflow, overflow, or input longer than 1,024 values returns `-1`. Empty input is valid.

For each pop, peek, and empty-check result, the benchmark adds `(operation_index + 1) * (observed_value + 1,000,000)` to a checksum. It then adds each remaining stack value in bottom-to-top order, weighted by its one-based position after the operations. This makes the result sensitive to operation order and remaining contents; valid results are nonnegative and do not overflow signed 64-bit under the stated limits.

The executable workload is in [`workload.json`](workload.json). The verifier independently checks 10,608 traces per implementation: all operation sequences through length five over six representative operations, deterministic randomized valid and malformed inputs, capacity and length boundaries, and the recorded workload.

## Implementations

The nine portable implementations are in [`c/s/stack.c`](../../../c/s/stack.c), [`c3/s/stack.c3`](../../../c3/s/stack.c3), [`cpp/s/stack.cpp`](../../../cpp/s/stack.cpp), [`elisa/s/stack.elisa`](../../../elisa/s/stack.elisa), [`nim/s/stack.nim`](../../../nim/s/stack.nim), [`odin/s/stack.odin`](../../../odin/s/stack.odin), [`rust/s/stack.rs`](../../../rust/s/stack.rs), [`v/s/stack.v`](../../../v/s/stack.v), and [`zig/s/stack.zig`](../../../zig/s/stack.zig). They use generic compiler targets and no architecture-specific instructions.

Run `python3 benchmarks/verify_stack.py --elisa-compiler PATH/TO/elisac` to check all nine implementations against the independent oracle and validate the workload records.

## Upstream references

- [C root stack](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/stack.c), [C dynamic-array stack](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/stack/stack.c), and [C linked-list stack](https://github.com/TheAlgorithms/C/blob/e5dad3fa8def3726ec850ca66a7f51521f8ad393/data_structures/stack/stack_linked_list/stack.c)
- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/stack.hpp)
- [Elixir](https://github.com/TheAlgorithms/Elixir/blob/6212e7e905ec2d2687e7f6e9e4b07b7fabb40f19/lib/data_structures/stack.ex)
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/datastructures/stacks/Stack.java)
- [JavaScript](https://github.com/TheAlgorithms/JavaScript/blob/5c39e87a9a31f279c60f830ad74a845e4788a517/Data-Structures/Stack/Stack.js)
- [PHP](https://github.com/TheAlgorithms/PHP/blob/b8a54469cc36332ef2934101b58d71075ef1d78e/DataStructures/Stack.php)
- [Python](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/stack.py)
- [Ruby](https://github.com/TheAlgorithms/Ruby/blob/bda11bdfd83b7958e1ca98247e5e43100ca88865/data_structures/stacks/stack.rb)
- [Swift](https://github.com/TheAlgorithms/Swift/blob/2c9eb8b85dee6db46cb33452c0b904eb7d7d179c/data_structures/Stack/stack.swift)
- [TypeScript](https://github.com/TheAlgorithms/TypeScript/blob/19b4ced86c99815f142d4a46a028f55487b8038a/data_structures/stack/stack.ts)
- [Zig](https://github.com/TheAlgorithms/Zig/blob/86c96a3fd0da17623ab5f6e3ced0d77ed8ce6cf3/dataStructures/stack.zig)
- Array-backed aliases: [C# dynamically resizing stack](https://github.com/TheAlgorithms/C-Sharp/blob/96e2905cab7bc6b33ac0a34ee5bb82ddccbcbb6c/DataStructures/Stack/ArrayBasedStack.cs) and [Dart fixed-capacity stack](https://github.com/TheAlgorithms/Dart/blob/73da8ab4ea413eee9bf29aa2263157d86060f871/data_structures/Stack/Array_Stack.dart)
