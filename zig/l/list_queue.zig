const MAX_QUEUE_SIZE: usize = 10;
const MAX_OPS: usize = 64;
const MAX_INPUT_LENGTH: usize = 129;
const MAX_OUTPUT_WORDS: usize = 130;

fn putI32Le(output: [*]u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn list_queue(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64, @intCast(MAX_OPS))) return -1;
    const op_count: usize = @intCast(input[0]);
    var queue: [MAX_QUEUE_SIZE]i32 = [_]i32{0} ** MAX_QUEUE_SIZE;
    var words: [MAX_OUTPUT_WORDS]i32 = undefined;
    var word_count: usize = 1;
    var query_count: usize = 0;
    var pos: usize = 1;
    var queue_size: usize = 0;
    for (0..op_count) |_| {
        if (pos >= length) return -1;
        const opcode = input[pos];
        pos += 1;
        if (opcode == 0) {
            if (pos >= length) return -1;
            const raw = input[pos];
            pos += 1;
            if (raw < -2147483648 or raw > 2147483647 or queue_size >= MAX_QUEUE_SIZE) return -1;
            queue[queue_size] = @intCast(raw);
            queue_size += 1;
        } else if (opcode == 1) {
            if (queue_size == 0) {
                words[word_count] = 3;
                words[word_count + 1] = 0;
            } else {
                const value = queue[0];
                for (0..MAX_QUEUE_SIZE - 1) |i| queue[i] = queue[i + 1];
                queue_size -= 1;
                words[word_count] = 1;
                words[word_count + 1] = value;
            }
            word_count += 2;
            query_count += 1;
        } else if (opcode == 2) {
            words[word_count] = 2;
            words[word_count + 1] = @intCast(queue_size);
            word_count += 2;
            query_count += 1;
        } else return -1;
    }
    if (pos != length or word_count + 1 + queue_size > MAX_OUTPUT_WORDS) return -1;
    words[0] = @intCast(query_count);
    words[word_count] = @intCast(queue_size);
    word_count += 1;
    for (0..queue_size) |i| {
        words[word_count] = queue[i];
        word_count += 1;
    }
    const bytes = word_count * 4;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    var buffer: [MAX_OUTPUT_WORDS * 4]u8 = undefined;
    for (0..word_count) |i| putI32Le(&buffer, i * 4, words[i]);
    for (0..bytes) |i| output[i] = buffer[i];
    return @intCast(bytes);
}
