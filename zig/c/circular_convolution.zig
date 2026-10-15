export fn circular_convolution(values: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (values == null or length < 4) return -1;
    const input = values.?[0..length];
    const raw_a_length = input[0];
    const raw_b_length = input[1];
    if (raw_a_length < 1 or raw_a_length > 8 or raw_b_length < 1 or raw_b_length > 8) return -1;
    const a_length: usize = @intCast(raw_a_length);
    const b_length: usize = @intCast(raw_b_length);
    if (length != 2 + a_length + b_length) return -1;
    for (input[2..]) |sample| {
        if (sample < -2 or sample > 2) return -1;
    }
    const n = @max(a_length, b_length);
    if (output == null or output_capacity < n) return -2;
    const result = output.?[0..output_capacity];

    for (0..n) |k| {
        var sum: i64 = 0;
        for (0..n) |i| {
            const b_index = (k + n - i) % n;
            const a_value: i64 = if (i < a_length) input[2 + i] else 0;
            const b_value: i64 = if (b_index < b_length) input[2 + a_length + b_index] else 0;
            sum += a_value * b_value;
        }
        result[k] = @intCast(if (sum < 0) sum + 256 else sum);
    }
    return @intCast(n);
}
