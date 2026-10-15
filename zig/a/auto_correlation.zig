fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @intCast((bits >> @intCast(byte * 8)) & 0xff);
    }
}

export fn auto_correlation(values: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > 65) return -1;
    const input = values.?[0..length];
    const raw_count = input[0];
    if (raw_count < 1 or raw_count > 64) return -1;
    const count: usize = @intCast(raw_count);
    if (length != count + 1) return -1;
    for (input[1..]) |sample| {
        if (sample < -1_000_000 or sample > 1_000_000) return -1;
    }
    const result_count = 2 * count - 1;
    const byte_count = 8 * result_count;
    if (output == null or output_capacity < byte_count) return -2;
    const result = output.?[0..output_capacity];

    var y_start = count;
    for (0..result_count) |index| {
        if (index < count) y_start -= 1;
        const k_min = if (index >= count - 1) index - (count - 1) else 0;
        const k_max = if (index < count) index else count - 1;
        var offset: usize = 0;
        var sum: i64 = 0;
        for (k_min..k_max + 1) |k| {
            sum += input[k + 1] * input[y_start + offset + 1];
            offset += 1;
        }
        storeI64Le(result.ptr, index * 8, sum);
    }
    return @intCast(byte_count);
}
