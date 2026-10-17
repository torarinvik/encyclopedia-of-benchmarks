export fn stock_span_problem(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 66) return -1;
    const values = input.?;
    const count_value = values[0];
    if (count_value < 1 or count_value > 64) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 1) return -1;
    for (0..count) |day| {
        const price = values[day + 1];
        if (price < -2147483648 or price > 2147483647) return -1;
    }

    const output_bytes = count * 8;
    if (output == null or capacity < output_bytes) return -2;
    var decreasing: [64]usize = @splat(0);
    var top: usize = 0;
    const destination = output.?;
    for (0..count) |day| {
        const price = values[day + 1];
        while (top > 0 and values[decreasing[top - 1] + 1] <= price) top -= 1;
        const span = if (top == 0) day + 1 else day - decreasing[top - 1];
        const encoded: u64 = @intCast(span);
        for (0..8) |byte| destination[day * 8 + byte] = @truncate(encoded >> @intCast(byte * 8));
        decreasing[top] = day;
        top += 1;
    }
    return count_value;
}
