const MAX_COUNT: usize = 256;
const MAX_INPUT_LENGTH: usize = 5;
const MAX_OUTPUT_BYTES: usize = MAX_COUNT * 4;

fn writeU32Le(output: []u8, index: usize, value: u32) void {
    const offset = index * 4;
    for (0..4) |byte| output[offset + byte] = @truncate(value >> @intCast(byte * 8));
}

export fn pcg32_random(values_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (values_opt == null or length < 4 or length > MAX_INPUT_LENGTH) return -1;
    if (length != 4) return -1;
    const values = values_opt.?;

    const seed: u64 = @bitCast(values[0]);
    const multiplier: u64 = @bitCast(values[1]);
    const stream_value = values[2];
    const count_value = values[3];
    if (stream_value < 0 or count_value < 0 or count_value > 256) return -1;

    const stream: u64 = @intCast(stream_value);
    const increment = (stream << 1) | 1;
    var state = seed +% increment;
    state = state *% multiplier +% increment;
    const count: usize = @intCast(count_value);
    const required_bytes = count * 4;
    if (required_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output_opt == null or output_capacity < required_bytes) return -2;
    const output = output_opt.?[0..required_bytes];

    for (0..count) |index| {
        var value = state;
        const rotation: u5 = @intCast(value >> 59);
        state = state *% multiplier +% increment;
        value ^= value >> 18;
        const xorshifted: u32 = @truncate(value >> 27);
        const left_shift: u5 = @intCast((32 - @as(u32, rotation)) & 31);
        const rotated = (xorshifted >> rotation) | (xorshifted << left_shift);
        writeU32Le(output, index, rotated);
    }
    return @intCast(required_bytes);
}
