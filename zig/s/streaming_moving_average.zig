fn putF64Le(out: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn streaming_moving_average(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const window_value = input[0];
    const count_value = input[1];
    if (window_value < 1 or window_value > 256 or count_value < 1 or count_value > 256) return -1;
    const window: usize = @intCast(window_value);
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;
    const data = input[2..][0..count];
    for (data) |value| if (value < -2147483648 or value > 2147483647) return -1;
    if (capacity < count * 8 or output == null) return -2;
    for (0..count) |i| {
        const start = if (i + 1 > window) i + 1 - window else 0;
        var sum: i64 = 0;
        for (start..i + 1) |j| sum += data[j];
        const average = @as(f64, @floatFromInt(sum)) / @as(f64, @floatFromInt(i + 1 - start));
        putF64Le(output, i * 8, average);
    }
    return @intCast(count * 8);
}
