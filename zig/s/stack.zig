/// Bounded array-backed integer stack with a deterministic operation-trace checksum.
export fn stack_benchmark(values: [*]const i64, length: usize) i64 {
    if (length > 1024 or length % 2 != 0) return -1;
    const operation_count = length / 2;
    var data_stack: [256]i64 = undefined;
    var top: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const opcode = values[2 * operation];
        const payload = values[2 * operation + 1];
        var observed: i64 = 0;
        var returns_value = true;
        if (opcode == 0) {
            if (payload < -1_000_000 or payload > 1_000_000 or top == 256) return -1;
            data_stack[top] = payload;
            top += 1;
            returns_value = false;
        } else if (opcode == 1) {
            if (payload != 0 or top == 0) return -1;
            top -= 1;
            observed = data_stack[top];
        } else if (opcode == 2) {
            if (payload != 0 or top == 0) return -1;
            observed = data_stack[top - 1];
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = if (top == 0) 1 else 0;
        } else return -1;
        if (returns_value) checksum += (@as(i64, @intCast(operation)) + 1) * (observed + 1_000_000);
    }
    for (0..top) |index| {
        checksum += (@as(i64, @intCast(operation_count + index)) + 1) * (data_stack[index] + 1_000_000);
    }
    return checksum;
}
