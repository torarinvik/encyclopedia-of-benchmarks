export fn z_algorithm(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 1 or length > 2048) return -1;
    if (input[0] < 0 or input[0] > 2047) return -1;
    const count: usize = @intCast(input[0]);
    if (length != count + 1) return -1;
    const output_bytes = count * 4;
    if (output_capacity < output_bytes) return -2;

    var z: [2047]usize = @splat(0);
    var left: usize = 0;
    var right: usize = 0;
    for (1..count) |index| {
        if (index < right) z[index] = @min(z[index - left], right - index);
        while (index + z[index] < count and input[1 + z[index]] == input[1 + index + z[index]]) {
            z[index] += 1;
        }
        if (index + z[index] > right) {
            left = index;
            right = index + z[index];
        }
    }
    for (0..count) |index| {
        const value: u32 = @intCast(z[index]);
        for (0..4) |byte| {
            output[index * 4 + byte] = @truncate(value >> @as(u5, @intCast(byte * 8)));
        }
    }
    return @intCast(count);
}
