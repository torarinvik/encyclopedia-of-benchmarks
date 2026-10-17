const MAX_NODES: usize = 16;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 5 + MAX_OPERATIONS;
const MAX_OUTPUT_WORDS: usize = 2 * MAX_OPERATIONS;
const PAIRS = [_][2]usize{ .{ 0, 1 }, .{ 0, 2 }, .{ 1, 0 }, .{ 1, 2 }, .{ 2, 0 }, .{ 2, 1 } };

fn append(words: *[MAX_OUTPUT_WORDS]i64, count: *usize, value: i64) void {
    words[count.*] = value;
    count.* += 1;
}

fn put_i64_le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn pncounter(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > 16 or input[4] < 0 or input[4] > 64) return -1;

    const node_count: usize = @intCast(input[0]);
    var ids: [3]usize = undefined;
    for (0..3) |counter| {
        if (input[1 + counter] < 0 or input[1 + counter] >= input[0]) return -1;
        ids[counter] = @intCast(input[1 + counter]);
    }
    const operation_count: usize = @intCast(input[4]);
    if (length != 5 + operation_count) return -1;

    var positive = [_][MAX_NODES]i64{[_]i64{0} ** MAX_NODES} ** 3;
    var negative = [_][MAX_NODES]i64{[_]i64{0} ** MAX_NODES} ** 3;
    var words = [_]i64{0} ** MAX_OUTPUT_WORDS;
    var word_count: usize = 0;
    var position: usize = 5;

    for (0..operation_count) |_| {
        const opcode = input[position];
        position += 1;
        if (opcode < 0 or opcode > 20) return -1;
        if (opcode < 6) {
            const counter: usize = @intCast(@divTrunc(opcode, 2));
            if (@mod(opcode, 2) == 0) positive[counter][ids[counter]] += 1
            else negative[counter][ids[counter]] += 1;
            append(&words, &word_count, opcode);
        } else if (opcode < 9) {
            const counter: usize = @intCast(opcode - 6);
            var value: i64 = 0;
            for (0..node_count) |node| value += positive[counter][node] - negative[counter][node];
            append(&words, &word_count, opcode);
            append(&words, &word_count, value);
        } else if (opcode < 15) {
            const pair: usize = @intCast(opcode - 9);
            const target = PAIRS[pair][0];
            const source = PAIRS[pair][1];
            for (0..node_count) |node| {
                positive[target][node] = @max(positive[target][node], positive[source][node]);
                negative[target][node] = @max(negative[target][node], negative[source][node]);
            }
            append(&words, &word_count, opcode);
        } else {
            const pair: usize = @intCast(opcode - 15);
            const left = PAIRS[pair][0];
            const right = PAIRS[pair][1];
            var result: i64 = 1;
            for (0..node_count) |node| {
                if (positive[left][node] > positive[right][node] and
                    negative[left][node] > negative[right][node]) {
                    result = 0;
                    break;
                }
            }
            append(&words, &word_count, opcode);
            append(&words, &word_count, result);
        }
    }

    const output_length = word_count * 8;
    const output = output_opt orelse return -2;
    if (output_capacity < output_length) return -2;
    for (0..word_count) |i| put_i64_le(output, i * 8, words[i]);
    return @intCast(output_length);
}
