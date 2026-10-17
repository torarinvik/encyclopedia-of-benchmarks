const MAX_OPERATIONS = 256;
const MAX_INPUT_LENGTH = 770;

fn storeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn fixed_priority_queue_using_list(input_opt: ?[*]const i64, length: usize,
                                           output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const operation_count_value = input[0];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS or
        length != 1 + 3 * @as(usize, @intCast(operation_count_value))) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    var buckets: [3][100]i32 = [_][100]i32{[_]i32{0} ** 100} ** 3;
    var counts = [_]usize{0} ** 3;
    var dequeued = [_]i64{0} ** 128;
    var dequeued_count: usize = 0;
    for (0..operation_count) |index| {
        const opcode = input[1 + 3 * index];
        const priority = input[2 + 3 * index];
        const data = input[3 + 3 * index];
        if (opcode == 0) {
            if (priority < -3 or priority > 2 or data < -2147483648 or data > 2147483647) return -1;
            const bucket: usize = @intCast(if (priority < 0) priority + 3 else priority);
            if (counts[bucket] == 100) return -1;
            buckets[bucket][counts[bucket]] = @intCast(data);
            counts[bucket] += 1;
        } else if (opcode == 1) {
            if (priority != 0 or data != 0) return -1;
            var bucket: usize = 0;
            while (bucket < 3 and counts[bucket] == 0) : (bucket += 1) {}
            if (bucket == 3) return -1;
            dequeued[dequeued_count] = buckets[bucket][0];
            dequeued_count += 1;
            counts[bucket] -= 1;
            for (0..counts[bucket]) |position| buckets[bucket][position] = buckets[bucket][position + 1];
        } else return -1;
    }
    const output_bytes = dequeued_count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..dequeued_count) |index| storeI64(output, index * 8, dequeued[index]);
    return @intCast(output_bytes);
}
