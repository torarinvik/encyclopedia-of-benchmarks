const MAX_N: usize = 8;
const MAX_M: usize = 8;
const MAX_PARSEABLE: usize = 19;

fn multiplyInField(left: u64, right: u64) u64 {
    var result: u64 = 0;
    var shifted = left;
    var multiplier = right;
    for (0..64) |_| {
        if ((multiplier & 1) != 0) result ^= shifted;
        const carry = shifted >> 63;
        shifted <<= 1;
        if (carry != 0) shifted ^= 0x1b;
        multiplier >>= 1;
    }
    return result;
}

fn solve(input: []const i64, output: []u8) i64 {
    if (input.len < 2 or input.len > MAX_PARSEABLE) return -1;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N))
            or input[1] < 1 or input[1] > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (input.len != 2 + n + m) return -1;
    const count = n + m - 1;
    const needed = 8 * count;
    if (output.len < needed) return -2;

    var product = [_]u64{0} ** (MAX_N + MAX_M - 1);
    for (0..n) |i| {
        const left: u64 = @bitCast(input[2 + i]);
        for (0..m) |j| {
            const right: u64 = @bitCast(input[2 + n + j]);
            product[i + j] ^= multiplyInField(left, right);
        }
    }
    for (0..count) |i| {
        for (0..8) |byte| output[8 * i + byte] = @truncate(product[i] >> @intCast(8 * byte));
    }
    return @intCast(needed);
}

export fn convolution_f2_64(input_opt: ?[*]const i64, length: usize,
        output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N))
            or input[1] < 1 or input[1] > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + n + m) return -1;
    const needed = 8 * (n + m - 1);
    const output = output_opt orelse return -2;
    if (output_capacity < needed) return -2;
    return solve(input, output[0..needed]);
}
