/// Amortized FIFO queue implemented with an input and an output stack.
export fn queue_using_two_stacks_benchmark(values: [*]const i64, length: usize) i64 {
    if (length > 1024 or length % 2 != 0) return -1;
    const operation_count = length / 2;
    var in_stack: [256]i64 = undefined;
    var out_stack: [256]i64 = undefined;
    var in_count: usize = 0;
    var out_count: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const opcode = values[2 * operation];
        const payload = values[2 * operation + 1];
        var observed: i64 = 0;
        var returns_value = true;
        if (opcode == 0) {
            if (payload < -1_000_000 or payload > 1_000_000 or in_count + out_count == 256) return -1;
            in_stack[in_count] = payload;
            in_count += 1;
            returns_value = false;
        } else if (opcode == 1 or opcode == 2) {
            if (payload != 0) return -1;
            if (out_count == 0) {
                while (in_count > 0) {
                    in_count -= 1;
                    out_stack[out_count] = in_stack[in_count];
                    out_count += 1;
                }
            }
            if (out_count == 0) return -1;
            if (opcode == 1) {
                out_count -= 1;
                observed = out_stack[out_count];
            } else {
                observed = out_stack[out_count - 1];
            }
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = if (in_count + out_count == 0) 1 else 0;
        } else if (opcode == 4) {
            if (payload != 0) return -1;
            observed = @intCast(in_count + out_count);
        } else return -1;
        if (returns_value) checksum += (@as(i64, @intCast(operation)) + 1) * (observed + 1_000_000);
    }
    for (0..out_count) |index| {
        checksum += (@as(i64, @intCast(operation_count + index)) + 1)
            * (out_stack[out_count - index - 1] + 1_000_000);
    }
    for (0..in_count) |index| {
        checksum += (@as(i64, @intCast(operation_count + out_count + index)) + 1)
            * (in_stack[index] + 1_000_000);
    }
    return checksum;
}
