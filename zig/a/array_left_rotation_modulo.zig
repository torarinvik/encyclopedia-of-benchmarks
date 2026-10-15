/// Return a fresh left rotation; nonpositive shifts keep order and positive shifts wrap.
const MAX_ARRAY_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = MAX_ARRAY_LENGTH + 1;

fn write_i32_le(output: [*]u8, index: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[index * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn array_left_rotation_modulo(input: [*]const i64, length: usize,
                                     output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const rotations = input[0];
    if (rotations < -2147483648 or rotations > 2147483647) return -1;
    const count = length - 1;
    var values: [MAX_ARRAY_LENGTH]i32 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = @intCast(value);
    }
    if (count == 0) return 0;
    const shift: usize = if (rotations > 0) @intCast(@as(u64, @intCast(rotations)) % count) else 0;
    const output_bytes = count * 4;
    if (output_capacity < output_bytes) return -2;
    for (shift..count) |index| write_i32_le(output, index - shift, values[index]);
    for (0..shift) |index| write_i32_le(output, count - shift + index, values[index]);
    return @intCast(count);
}

