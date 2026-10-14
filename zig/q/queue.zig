/// Bounded ring-buffer queue with a deterministic operation-trace checksum.
export fn queue_benchmark(values: [*]const i64, length: usize) i64 {
    if (length > 1024 or length % 2 != 0) return -1;
    const operation_count = length / 2;
    var data_queue: [256]i64 = undefined;
    var head: usize = 0;
    var count: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const opcode = values[2 * operation];
        const payload = values[2 * operation + 1];
        var observed: i64 = 0;
        var returns_value = true;
        if (opcode == 0) {
            if (payload < -1_000_000 or payload > 1_000_000 or count == 256) return -1;
            data_queue[(head + count) % 256] = payload;
            count += 1;
            returns_value = false;
        } else if (opcode == 1) {
            if (payload != 0 or count == 0) return -1;
            observed = data_queue[head];
            head = (head + 1) % 256;
            count -= 1;
        } else if (opcode == 2) {
            if (payload != 0 or count == 0) return -1;
            observed = data_queue[head];
        } else if (opcode == 3) {
            if (payload != 0 or count == 0) return -1;
            observed = data_queue[(head + count - 1) % 256];
        } else if (opcode == 4) {
            if (payload != 0) return -1;
            observed = if (count == 0) 1 else 0;
        } else if (opcode == 5) {
            if (payload != 0) return -1;
            observed = @intCast(count);
        } else return -1;
        if (returns_value) checksum += (@as(i64, @intCast(operation)) + 1) * (observed + 1_000_000);
    }
    for (0..count) |index| {
        checksum += (@as(i64, @intCast(operation_count + index)) + 1)
            * (data_queue[(head + index) % 256] + 1_000_000);
    }
    return checksum;
}
