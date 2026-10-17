const MAX_OPS: usize = 128;

fn push_new(main: *[MAX_OPS]i64, temp: *[MAX_OPS]i64,
            head: *usize, tail: *usize, value: i64) void {
    var temp_tail: usize = 0;
    temp[temp_tail] = value;
    temp_tail += 1;
    while (head.* < tail.*) {
        temp[temp_tail] = main[head.*];
        temp_tail += 1;
        head.* += 1;
    }
    head.* = 0;
    tail.* = temp_tail;
}

export fn stack_using_two_queues(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > 257) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_OPS or length != 1 + 2 * @as(usize, @intCast(input[0]))) return -1;
    var queue_a: [MAX_OPS]i64 = undefined;
    var queue_b: [MAX_OPS]i64 = undefined;
    var tags: [MAX_OPS]i64 = undefined;
    var results: [MAX_OPS]i64 = undefined;
    var main_is_a = true;
    var head: usize = 0;
    var tail: usize = 0;
    var record_count: usize = 0;
    var pos: usize = 1;
    for (0..@intCast(input[0])) |_| {
        const opcode = input[pos];
        const operand = input[pos + 1];
        pos += 2;
        if (opcode == 0) {
            if (operand < -2147483648 or operand > 2147483647) return -1;
            if (main_is_a) push_new(&queue_a, &queue_b, &head, &tail, operand)
            else push_new(&queue_b, &queue_a, &head, &tail, operand);
            main_is_a = !main_is_a;
        } else if (opcode == 1) {
            if (operand != 0 or head == tail) return -1;
            tags[record_count] = 0;
            results[record_count] = if (main_is_a) queue_a[head] else queue_b[head];
            record_count += 1;
            head += 1;
        } else if (opcode == 2) {
            if (operand != 0) return -1;
            if (head == tail) {
                tags[record_count] = 1;
                results[record_count] = 0;
            } else {
                tags[record_count] = 0;
                results[record_count] = if (main_is_a) queue_a[head] else queue_b[head];
            }
            record_count += 1;
        } else return -1;
    }
    const bytes = record_count * 16;
    if (output_opt == null or output_capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..record_count) |i| {
        const words = [_]i64{tags[i], results[i]};
        for (0..2) |w| {
            const bits: u64 = @bitCast(words[w]);
            for (0..8) |b| output[16*i+8*w+b] = @truncate(bits >> @intCast(8*b));
        }
    }
    return @intCast(bytes);
}
