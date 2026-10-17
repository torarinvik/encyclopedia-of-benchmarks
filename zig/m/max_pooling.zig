const MAX_N: usize = 16;
const MAX_INPUT_WORDS: usize = 3 + MAX_N * MAX_N;
const MAX_PARSEABLE_INPUT_WORDS: usize = MAX_INPUT_WORDS + 1;
const MAX_OUTPUT_BYTES: usize = 8 * MAX_N * MAX_N;

fn putF64Le(output: []u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn max_pooling(input_opt: ?[*]const i32, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE_INPUT_WORDS) return -1;
    const input = input_opt.?;
    const n = input[0]; const size = input[1]; const stride = input[2];
    if (n < 1 or n > 16 or size < 1 or size > n or stride < 1 or stride > 16 or
        length != 3 + @as(usize, @intCast(n)) * @as(usize, @intCast(n))) return -1;
    const side: usize = @intCast(n);
    for (0..side * side) |i| if (input[3 + i] < -1_000_000 or input[3 + i] > 1_000_000) return -1;
    const out_side: usize = @intCast((n - size) / stride + 1);
    const output_count = out_side * out_side;
    const bytes = output_count * 8;
    if (output_opt == null or capacity < bytes) return -2;
    var buffer: [MAX_OUTPUT_BYTES]u8 = undefined;
    var position: usize = 0;
    for (0..out_side) |row| {
        for (0..out_side) |col| {
            const start_row = row * @as(usize, @intCast(stride));
            const start_col = col * @as(usize, @intCast(stride));
            var maximum = input[3 + start_row * side + start_col];
            for (0..@intCast(size)) |r| for (0..@intCast(size)) |c| {
                const value = input[3 + (start_row + r) * side + start_col + c];
                if (value > maximum) maximum = value;
            };
            putF64Le(&buffer, position, @floatFromInt(maximum));
            position += 8;
        }
    }
    const output = output_opt.?;
    for (0..bytes) |i| output[i] = buffer[i];
    return @intCast(bytes);
}
