fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn convolution(values: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (values == null or length < 4 or length > 130) return -1;
    const input = values.?[0..length];
    const raw_a = input[0];
    const raw_b = input[1];
    if (raw_a < 1 or raw_a > 64 or raw_b < 1 or raw_b > 64) return -1;
    const a_count: usize = @intCast(raw_a);
    const b_count: usize = @intCast(raw_b);
    if (length != a_count + b_count + 2) return -1;
    for (input[2..]) |value| {
        if (value < -1_000_000 or value > 1_000_000) return -1;
    }
    const result_count = a_count + b_count - 1;
    const byte_count = result_count * 8;
    if (output == null or capacity < byte_count) return -2;
    const result = output.?[0..byte_count];
    for (0..result_count) |i| {
        const k_start = if (i >= b_count - 1) i - (b_count - 1) else 0;
        const k_end = if (i < a_count) i else a_count - 1;
        var sum: i64 = 0;
        for (k_start..k_end + 1) |k| sum += input[k + 2] * input[a_count + (i - k) + 2];
        storeI64Le(result.ptr, i * 8, sum);
    }
    return @intCast(byte_count);
}
