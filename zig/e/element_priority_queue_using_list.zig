const MAX_OPERATIONS = 256;
const MAX_INPUT_LENGTH = 514;

fn storeI64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn element_priority_queue_using_list(input_opt: ?[*]const i64, length: usize,
                                             output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    const operation_count_value = input[0];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS or
        length != 1 + 2 * @as(usize, @intCast(operation_count_value))) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    var queue = [_]i32{0} ** 100;
    var queue_count: usize = 0;
    var dequeued = [_]i64{0} ** 128;
    var dequeued_count: usize = 0;
    for (0..operation_count) |index| {
        const opcode = input[1 + 2 * index];
        const argument = input[2 + 2 * index];
        if (opcode == 0) {
            if (argument < -2147483648 or argument > 2147483647 or queue_count == 100) return -1;
            queue[queue_count] = @intCast(argument);
            queue_count += 1;
        } else if (opcode == 1) {
            if (argument != 0 or queue_count == 0) return -1;
            var minimum: usize = 0;
            for (1..queue_count) |position| if (queue[position] < queue[minimum]) { minimum = position; };
            dequeued[dequeued_count] = queue[minimum];
            dequeued_count += 1;
            queue_count -= 1;
            for (minimum..queue_count) |position| queue[position] = queue[position + 1];
        } else return -1;
    }
    const output_bytes = dequeued_count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..dequeued_count) |index| storeI64(output, index * 8, dequeued[index]);
    return @intCast(output_bytes);
}
