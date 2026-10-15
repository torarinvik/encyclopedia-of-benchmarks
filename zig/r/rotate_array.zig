/// Rotate an array right by repeating a one-place shift.
const MAX_ARRAY_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = MAX_ARRAY_LENGTH + 1;
const MAX_ROTATIONS: i64 = 1024;

export fn rotate_array(input: [*]const i64, length: usize,
                       output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const rotations = input[0];
    if (rotations < 0 or rotations > MAX_ROTATIONS) return -1;
    const count = length - 1;
    var values: [MAX_ARRAY_LENGTH]i32 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = @intCast(value);
    }
    const output_bytes = count * 4;
    if (output_capacity < output_bytes) return -2;
    for (0..@intCast(rotations)) |_| {
        if (count > 1) {
            const last = values[count - 1];
            var index = count - 1;
            while (index > 0) : (index -= 1) values[index] = values[index - 1];
            values[0] = last;
        }
    }
    for (0..count) |index| {
        const bits: u32 = @bitCast(values[index]);
        for (0..4) |byte| output[index * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(count);
}
