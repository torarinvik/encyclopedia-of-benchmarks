const MAX_OPS: usize = 32;

export fn list_based_queue(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > 66) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_OPS) return -1;
    const op_count: usize = @intCast(input[0]);
    var node_values: [MAX_OPS]i32 = undefined;
    var next_node: [MAX_OPS]i32 = undefined;
    var words: [64]i64 = undefined;
    var allocated: usize = 0;
    var word_count: usize = 0;
    var pos: usize = 1;
    var size: usize = 0;
    var head: i32 = -1;
    var tail: i32 = -1;
    for (0..op_count) |_| {
        if (pos >= length) return -1;
        const opcode = input[pos]; pos += 1;
        if (opcode == 0) {
            if (pos >= length) return -1;
            const value = input[pos]; pos += 1;
            if (value < -2147483648 or value > 2147483647 or allocated >= MAX_OPS) return -1;
            const node: i32 = @intCast(allocated); allocated += 1;
            node_values[@intCast(node)] = @intCast(value);
            next_node[@intCast(node)] = -1;
            if (tail < 0) head = node else next_node[@intCast(tail)] = node;
            tail = node; size += 1;
            words[word_count] = 0; words[word_count + 1] = 1; word_count += 2;
        } else if (opcode == 1) {
            if (head < 0) return -1;
            const node = head;
            head = next_node[@intCast(node)];
            if (head < 0) tail = -1;
            size -= 1;
            words[word_count] = 1; words[word_count + 1] = @intCast(node_values[@intCast(node)]); word_count += 2;
        } else if (opcode == 2) {
            if (head < 0) return -1;
            words[word_count] = 2; words[word_count + 1] = @intCast(node_values[@intCast(head)]); word_count += 2;
        } else if (opcode == 3) {
            head = -1; tail = -1; size = 0;
            words[word_count] = 3; words[word_count + 1] = 1; word_count += 2;
        } else if (opcode == 4) {
            words[word_count] = 4; words[word_count + 1] = if (size == 0) 1 else 0; word_count += 2;
        } else if (opcode == 5) {
            words[word_count] = 5; words[word_count + 1] = 0; word_count += 2;
        } else return -1;
    }
    if (pos != length or length > 1 + 2 * op_count or word_count > 64) return -1;
    const bytes = word_count * 8;
    if (output_opt == null or output_capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..word_count) |i| {
        const bits: u64 = @bitCast(words[i]);
        for (0..8) |b| output[8 * i + b] = @intCast((bits >> @intCast(8 * b)) & 255);
    }
    return @intCast(bytes);
}
