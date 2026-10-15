/// Rotate by reversing the whole array, then each side of the rotation.
const MAX_ARRAY_LENGTH: usize = 1024;
const MAX_INPUT_LENGTH: usize = MAX_ARRAY_LENGTH + 1;

fn reverseRange(values: *[MAX_ARRAY_LENGTH]i32, start_value: usize, end_value: usize) void {
    var start = start_value;
    var ending = end_value;
    while (start < ending) {
        ending -= 1;
        if (start >= ending) break;
        const temporary = values[start];
        values[start] = values[ending];
        values[ending] = temporary;
        start += 1;
    }
}

export fn rotate_array_reversal(input: [*]const i64, length: usize,
                                output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const steps = input[0];
    if (steps < -2147483648 or steps > 2147483647) return -1;
    const count = length - 1;
    var values: [MAX_ARRAY_LENGTH]i32 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        values[index] = @intCast(value);
    }
    const output_bytes = count * 4;
    if (output_capacity < output_bytes) return -2;
    const shift: usize = if (count == 0) 0 else @intCast(@mod(steps, @as(i64, @intCast(count))));
    reverseRange(&values, 0, count);
    reverseRange(&values, 0, shift);
    reverseRange(&values, shift, count);
    for (0..count) |index| {
        const bits: u32 = @bitCast(values[index]);
        for (0..4) |byte| output[index * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(count);
}
