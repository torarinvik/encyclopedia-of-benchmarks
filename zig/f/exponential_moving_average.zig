fn putF64Le(out: [*]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| out[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn exponential_moving_average(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3) return -1;
    const window_value = input[0];
    const count_value = input[1];
    if (window_value < 2 or window_value > 32 or count_value < 1 or count_value > 256) return -1;
    const window: usize = @intCast(window_value);
    const count: usize = @intCast(count_value);
    if (length != count + 2) return -1;
    const prices = input[2..][0..count];
    for (prices) |price| if (price < -1_000_000 or price > 1_000_000) return -1;
    if (output == null or capacity < count * 8) return -2;
    const alpha = 2.0 / (1.0 + @as(f64, @floatFromInt(window)));
    var average: f64 = 0.0;
    for (prices, 0..) |raw_price, i| {
        const price: f64 = @floatFromInt(raw_price);
        if (i == 0) average = price
        else if (i <= window) average = (average + price) * 0.5
        else average = (alpha * price) + ((1.0 - alpha) * average);
        putF64Le(output, i * 8, average);
    }
    return @intCast(count * 8);
}
