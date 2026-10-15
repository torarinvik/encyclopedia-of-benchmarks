/// Emit the reflected n-bit Gray-code sequence as little-endian u32 values.
export fn gray_code(input: [*]const i64, input_length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (input_length != 1 or input[0] < 0 or input[0] > 13) return -1;
    const bit_count: u6 = @intCast(input[0]);
    const count: usize = if (bit_count == 0) 0 else @as(usize, 1) << bit_count;
    const required = count * 4;
    if (output_capacity < required) return -2;
    for (0..count) |index| {
        const gray = index ^ (index >> 1);
        for (0..4) |byte| output[4 * index + byte] = @truncate(gray >> @intCast(8 * byte));
    }
    return @intCast(count);
}
