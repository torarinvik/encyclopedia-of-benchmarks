/// Return a fresh right rotation; shifts at least as large as the array length yield empty output.
const MAX_ARRAY_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = MAX_ARRAY_LENGTH + 1;
const MAX_SHIFT: i64 = 2147483647;

fn write_i32_le(output: [*]u8, index: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[index * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn array_right_rotation_modulo(input: [*]const i64, length: usize,
                              output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const shift_value = input[0];
    if (shift_value < 0 or shift_value > MAX_SHIFT) return -1;
    const count = length - 1;
    var values: [MAX_ARRAY_LENGTH]i32 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = @intCast(value);
    }
    const shift_value: usize = @intCast(shift_value);
    if (count == 0) return -1;
    const shift: usize = shift_value % count;
    const output_bytes = count * 4;
    if (output_capacity < output_bytes) return -2;
    for (0..shift) |index| write_i32_le(output, index, values[count - shift + index]);
    for (0..(count - shift)) |index| write_i32_le(output, shift + index, values[index]);
    return @intCast(count);
}
