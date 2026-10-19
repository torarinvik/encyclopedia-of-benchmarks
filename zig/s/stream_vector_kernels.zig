fn writeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn stream_vector_kernels(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 259) return -1;
    const mode = input[0];
    const count_value = input[1];
    if (mode < 0 or mode > 3 or count_value < 0 or count_value > 128) return -1;
    const count: usize = @intCast(count_value);
    const has_alpha = mode == 1 or mode == 3;
    const array_count: usize = if (mode == 0 or mode == 1) 1 else 2;
    const alpha_count: usize = if (has_alpha) 1 else 0;
    const expected_length = 2 + alpha_count + array_count * count;
    if (length != expected_length) return -1;

    var a_start: usize = 2;
    var alpha: i64 = 0;
    if (has_alpha) {
        alpha = input[2];
        if (alpha < -1000 or alpha > 1000) return -1;
        a_start = 3;
    }
    const b_start = a_start + count;
    for (0..array_count * count) |index| {
        const value = input[a_start + index];
        if (value < -1000 or value > 1000) return -1;
    }

    var staged: [128]i64 = undefined;
    for (0..count) |index| {
        const a = input[a_start + index];
        staged[index] = switch (mode) {
            0 => a,
            1 => alpha * a,
            2 => a + input[b_start + index],
            else => a + alpha * input[b_start + index],
        };
    }

    const output_bytes = count * 8;
    if (output == null or capacity < output_bytes) return -2;
    for (0..count) |index| writeI64Le(output, index * 8, staged[index]);
    return @intCast(output_bytes);
}
