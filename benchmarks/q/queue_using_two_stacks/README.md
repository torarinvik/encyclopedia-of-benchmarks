# Queue using two stacks

The pinned inventory contains this candidate in two C++ repositories and Java. The C++ copies eagerly reverse the active stack on every enqueue; Java keeps separate input and output stacks and transfers only when dequeue or peek needs the front. This benchmark standardizes on the lazy transfer strategy, so its operation cost follows the amortized two-stack queue method across all languages.

## Contract

The `i64_array_scalar` function accepts up to 1,024 signed 64-bit values encoded as `[opcode, payload]` pairs, for at most 512 operations. The two stacks together hold at most 256 values. Operations are:

- `0`: enqueue a payload in -1,000,000 through 1,000,000
- `1`: dequeue, with payload zero
- `2`: peek at the front, with payload zero
- `3`: report whether the queue is empty, with payload zero
- `4`: report the queue size, with payload zero

An odd-length input, unknown opcode, invalid payload, dequeue or peek on an empty queue, queue overflow, or input longer than 1,024 values returns `-1`. Empty input is valid.

Each dequeue, peek, empty check, and size result contributes `(operation_index + 1) * (observed_value + 1,000,000)` to a checksum. Remaining queue values contribute front-to-back, weighted by their one-based positions after the operations. Valid results are nonnegative and fit in signed 64-bit.

[`workload.json`](workload.json) has 20 recorded cases, including a full 256-value transfer and drain. The verifier checks 20,508 traces per implementation: all sequences through length five over representative operations, deterministic randomized valid and malformed traces, capacity boundaries, and the recorded workload.

## Implementations

The nine portable implementations are in [`c/q/queue_using_two_stacks.c`](../../../c/q/queue_using_two_stacks.c), [`c3/q/queue_using_two_stacks.c3`](../../../c3/q/queue_using_two_stacks.c3), [`cpp/q/queue_using_two_stacks.cpp`](../../../cpp/q/queue_using_two_stacks.cpp), [`elisa/q/queue_using_two_stacks.elisa`](../../../elisa/q/queue_using_two_stacks.elisa), [`nim/q/queue_using_two_stacks.nim`](../../../nim/q/queue_using_two_stacks.nim), [`odin/q/queue_using_two_stacks.odin`](../../../odin/q/queue_using_two_stacks.odin), [`rust/q/queue_using_two_stacks.rs`](../../../rust/q/queue_using_two_stacks.rs), [`v/q/queue_using_two_stacks.v`](../../../v/q/queue_using_two_stacks.v), and [`zig/q/queue_using_two_stacks.zig`](../../../zig/q/queue_using_two_stacks.zig). Builds use generic compiler targets and no architecture-specific instructions.

Run `python3 benchmarks/verify_queue_using_two_stacks.py --elisa-compiler PATH/TO/elisac` to check all implementations against the FIFO oracle and verify workload records.

## Upstream references

- [C++](https://github.com/TheAlgorithms/C-Plus-Plus/blob/fdcc29b0ac2848e9d1a8d926e171cc5b39f97759/data_structures/queue_using_two_stacks.cpp) and [additional C++ copy](https://github.com/TheAlgorithms/C-Plus-Plus-1/blob/0f20cdcf8f49c2b8f2c128a2ac7b22819a44a680/data_structures/queue_using_two_stacks.cpp)
- [Java](https://github.com/TheAlgorithms/Java/blob/e43ec3897e48f23843972d02cd05a5bb1b6864a2/src/main/java/com/thealgorithms/others/QueueUsingTwoStacks.java)
