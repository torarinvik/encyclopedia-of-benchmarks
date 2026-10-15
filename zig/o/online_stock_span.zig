const MAX_DAYS: usize = 4095;

export fn online_stock_span(input: [*]const i64, length: usize,
                            output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or input[0] < 1 or input[0] > 4095) return -1;
    const count: usize = @intCast(input[0]);
    if (length != count + 1) return -1;
    for (0..count) |day| {
        if (input[day + 1] < 1 or input[day + 1] > 100000) return -1;
    }
    const output_bytes = count * 8;
    if (output_capacity < output_bytes) return -2;

    var decreasing: [MAX_DAYS]usize = @splat(0);
    var top: usize = 0;
    for (0..count) |day| {
        const price = input[day + 1];
        while (top > 0 and input[decreasing[top - 1] + 1] <= price) top -= 1;
        const span = if (top == 0) day + 1 else day - decreasing[top - 1];
        const encoded: u64 = @intCast(span);
        for (0..8) |byte| output[day * 8 + byte] = @truncate(encoded >> @as(u6, @intCast(byte * 8)));
        decreasing[top] = day;
        top += 1;
    }
    return @intCast(count);
}
