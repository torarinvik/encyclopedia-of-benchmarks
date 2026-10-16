# Stack Tracking Min/Max

This package benchmarks the pinned [`MinMaxStack` Python source](https://github.com/TheAlgorithms/Python/blob/e1a2a8b016001309a73d5fec4818c35cca139795/data_structures/stacks/stack_tracking_min_max.py) as a bounded operation trace. It retains each element’s current value and running minimum and maximum, so min/max queries and validity checks are O(1). Empty pop/min/max calls return negative infinity; empty validity returns false. A push at capacity records the source exception and terminates execution. The source’s diagnostic print on empty validity checks is omitted.

Input is `[capacity, op_count, op_stream...]`; capacity and operation count are each 0..64. Opcode 1 consumes a signed-i32 value and pushes it, while 2/3/4/5 mean pop/min/max/valid. The packed input must describe exactly the declared operations, without trailing values.

Each executed operation emits three signed-i64 little-endian words `[opcode, tag, value]`. The tags are 0=int, 1=bool, 2=None, 3=negative infinity (value 0), and 4=terminal max-size exception (value 1). Output is buffered before the capacity check, so an insufficient output buffer returns `-2` without partial writes; malformed traces return `-1`. The maximum output is 1,536 bytes.

## Language ports

- C: [`c/s/stack_tracking_min_max.c`](../../../c/s/stack_tracking_min_max.c)
- C3: [`c3/s/stack_tracking_min_max.c3`](../../../c3/s/stack_tracking_min_max.c3)
- CPP: [`cpp/s/stack_tracking_min_max.cpp`](../../../cpp/s/stack_tracking_min_max.cpp)
- ELISA: [`elisa/s/stack_tracking_min_max.elisa`](../../../elisa/s/stack_tracking_min_max.elisa)
- NIM: [`nim/s/stack_tracking_min_max.nim`](../../../nim/s/stack_tracking_min_max.nim)
- ODIN: [`odin/s/stack_tracking_min_max.odin`](../../../odin/s/stack_tracking_min_max.odin)
- RUST: [`rust/s/stack_tracking_min_max.rs`](../../../rust/s/stack_tracking_min_max.rs)
- V: [`v/s/stack_tracking_min_max.v`](../../../v/s/stack_tracking_min_max.v)
- ZIG: [`zig/s/stack_tracking_min_max.zig`](../../../zig/s/stack_tracking_min_max.zig)
