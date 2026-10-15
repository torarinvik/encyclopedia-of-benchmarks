export fn reverse_string(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 256) return -1;
    const n: usize = @intCast(values[0]);
    if (length != n + 1) return -1;
    for (0..n) |i| {
        if (values[i + 1] < 33 or values[i + 1] > 126) return -1;
    }
    if (output == null or output_capacity < n + 1) return -2;
    const result = output.?[0..output_capacity];
    for (0..n) |i| {
        result[i] = @intCast(values[n - i]);
    }
    result[n] = 0;
    return @intCast(n);
}
