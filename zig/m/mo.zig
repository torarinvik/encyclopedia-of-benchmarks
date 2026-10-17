const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_VALUE: i32 = 255;
const MAX_PARSEABLE_INPUT_WORDS: usize = 2 + MAX_N + 2 * MAX_Q + 1;
const MAX_OUTPUT_BYTES: usize = 4 * MAX_Q;

const Query = struct { left: usize, right: usize, index: usize };

fn ceilSqrt(n: usize) usize {
    var block: usize = 1;
    while (block * block < n) block += 1;
    return block;
}

fn before(a: Query, b: Query, block_size: usize) bool {
    const a_block = a.left / block_size;
    const b_block = b.left / block_size;
    if (a_block != b_block) return a_block < b_block;
    return a.right < b.right;
}

fn putI32Le(output: []u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn mo(input_opt: ?[*]const i32, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_WORDS) return -1;
    const input = input_opt.?;
    const n_raw = input[0];
    if (n_raw < 1 or n_raw > @as(i32, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(n_raw);
    const q_offset = 1 + n;
    if (length <= q_offset) return -1;
    const q_raw = input[q_offset];
    if (q_raw < 0 or q_raw > @as(i32, @intCast(MAX_Q))) return -1;
    const q_count: usize = @intCast(q_raw);
    if (length != q_offset + 1 + 2 * q_count) return -1;
    for (0..n) |i| if (input[1 + i] < 0 or input[1 + i] > MAX_VALUE) return -1;

    var queries: [MAX_Q]Query = undefined;
    for (0..q_count) |i| {
        const left_raw = input[q_offset + 1 + 2 * i];
        const right_raw = input[q_offset + 2 + 2 * i];
        if (left_raw < 1 or right_raw < left_raw or right_raw > n_raw) return -1;
        queries[i] = .{ .left = @intCast(left_raw - 1), .right = @intCast(right_raw - 1), .index = i };
    }
    const bytes = 4 * q_count;
    if (output_opt == null or capacity < bytes) return -2;

    const block_size = ceilSqrt(n);
    for (1..q_count) |i| {
        const value = queries[i];
        var j = i;
        while (j > 0 and before(value, queries[j - 1], block_size)) : (j -= 1) queries[j] = queries[j - 1];
        queries[j] = value;
    }
    var frequencies: [256]i32 = [_]i32{0} ** 256;
    var answers: [MAX_Q]i32 = [_]i32{0} ** MAX_Q;
    var distinct: i32 = 0;
    var left: usize = 0;
    var right: usize = 0;
    for (0..q_count) |i| {
        const query = queries[i];
        while (left < query.left) {
            const value: usize = @intCast(input[1 + left]);
            left += 1;
            frequencies[value] -= 1;
            if (frequencies[value] == 0) distinct -= 1;
        }
        while (left > query.left) {
            left -= 1;
            const value: usize = @intCast(input[1 + left]);
            frequencies[value] += 1;
            if (frequencies[value] == 1) distinct += 1;
        }
        while (right <= query.right) {
            const value: usize = @intCast(input[1 + right]);
            frequencies[value] += 1;
            if (frequencies[value] == 1) distinct += 1;
            right += 1;
        }
        while (right > query.right + 1) {
            right -= 1;
            const value: usize = @intCast(input[1 + right]);
            frequencies[value] -= 1;
            if (frequencies[value] == 0) distinct -= 1;
        }
        answers[query.index] = distinct;
    }
    if (bytes == 0) return 0;
    const output = output_opt.?;
    var buffer: [MAX_OUTPUT_BYTES]u8 = undefined;
    for (0..q_count) |i| putI32Le(&buffer, 4 * i, answers[i]);
    for (0..bytes) |i| output[i] = buffer[i];
    return @intCast(bytes);
}
