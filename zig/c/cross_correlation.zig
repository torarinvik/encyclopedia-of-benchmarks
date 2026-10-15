fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
    }
}

export fn cross_correlation(values: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 4 or length > 66) return -1;
    const input = values.?[0..length];
    const raw_x_count = input[0];
    const raw_y_count = input[1];
    if (raw_x_count < 1 or raw_x_count > 32 or raw_y_count < 1 or raw_y_count > 32) return -1;
    const x_count: usize = @intCast(raw_x_count);
    const y_count: usize = @intCast(raw_y_count);
    if (length != x_count + y_count + 2) return -1;
    for (input[2..]) |sample| {
        if (sample < -1_000_000 or sample > 1_000_000) return -1;
    }
    const result_count = x_count + y_count - 1;
    const byte_count = 8 * result_count;
    if (output == null or output_capacity < byte_count) return -2;
    const result = output.?[0..output_capacity];

    var y_start = y_count;
    for (0..result_count) |index| {
        if (index < y_count) y_start -= 1;
        const k_min = if (index >= y_count - 1) index - (y_count - 1) else 0;
        const k_max = if (index < x_count) index else x_count - 1;
        var sum: i64 = 0;
        for (k_min..k_max + 1) |k| {
            const y_index = y_start + (k - k_min);
            sum += input[k + 2] * input[x_count + y_index + 2];
        }
        storeI64Le(result.ptr, index * 8, sum);
    }
    return @intCast(byte_count);
}
