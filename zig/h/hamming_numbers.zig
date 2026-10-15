export fn hamming_numbers(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length != 1 or input[0] < 1 or input[0] > 32) return -1;
    const count: usize = @intCast(input[0]);
    const output_bytes = count * 8;
    if (output_capacity < output_bytes) return -2;

    var values: [32]u64 = @splat(0);
    values[0] = 1;
    var i2: usize = 0;
    var i3: usize = 0;
    var i5: usize = 0;
    for (1..count) |index| {
        const c2 = values[i2] * 2;
        const c3 = values[i3] * 3;
        const c5 = values[i5] * 5;
        const next = @min(c2, @min(c3, c5));
        values[index] = next;
        if (c2 == next) i2 += 1;
        if (c3 == next) i3 += 1;
        if (c5 == next) i5 += 1;
    }
    for (0..count) |index| {
        for (0..8) |byte| {
            output[index * 8 + byte] = @truncate(values[index] >> @as(u6, @intCast(byte * 8)));
        }
    }
    return @intCast(count);
}
