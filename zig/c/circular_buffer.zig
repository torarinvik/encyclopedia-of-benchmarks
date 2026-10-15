/// Bounded circular buffer that overwrites the oldest item when full.
export fn circular_buffer_benchmark(values: [*]const i64, length: usize) i64 {
    if (length < 1 or length > 1025 or (length - 1) % 2 != 0) return -1;
    if (values[0] < 1 or values[0] > 256) return -1;
    const capacity: usize = @intCast(values[0]);
    const operation_count = (length - 1) / 2;
    const offset: i64 = 1_000_000;
    var buffer: [256]i64 = undefined;
    var head: usize = 0;
    var tail: usize = 0;
    var count: usize = 0;
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const opcode = values[1 + 2 * operation];
        const payload = values[2 + 2 * operation];
        var observed: i64 = 0;
        if (opcode == 0) {
            if (payload < 0 or payload > offset) return -1;
            const was_empty = count == 0;
            if (count == capacity) head = (head + 1) % capacity else count += 1;
            buffer[tail] = payload;
            tail = (tail + 1) % capacity;
            observed = if (was_empty) 1 else 0;
        } else if (opcode == 1) {
            if (payload != 0) return -1;
            if (count == 0) observed = -1 else {
                observed = buffer[head];
                head = (head + 1) % capacity;
                count -= 1;
            }
        } else if (opcode == 2) {
            if (payload != 0) return -1;
            observed = if (count == 0) 1 else 0;
        } else if (opcode == 3) {
            if (payload != 0) return -1;
            observed = if (count == capacity) 1 else 0;
        } else if (opcode == 4) {
            if (payload != 0) return -1;
            observed = @intCast(count);
        } else return -1;
        checksum += (@as(i64, @intCast(operation)) + 1) * (observed + offset);
    }
    for (0..count) |index| {
        checksum += (@as(i64, @intCast(operation_count + index)) + 1)
            * (buffer[(head + index) % capacity] + offset);
    }
    return checksum;
}
