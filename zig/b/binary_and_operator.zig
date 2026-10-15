export fn binary_and_operator(raw: [*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (length != 2) return -1;
    const a_value = raw[0]; const b_value = raw[1];
    if (a_value < 0 or a_value > 2147483647 or b_value < 0 or b_value > 2147483647) return -1;
    const a: u64 = @intCast(a_value); const b: u64 = @intCast(b_value);
    const largest = @max(a, b);
    var width: usize = 1;
    var remaining = largest;
    while (remaining > 1) : (remaining >>= 1) { width += 1; }
    const output_length = width + 2;
    if (capacity < output_length) return -2;
    const out = output orelse return -2;
    const result = a & b;
    out[0] = '0'; out[1] = 'b';
    for (0..width) |i| {
        const bit = width - 1 - i;
        out[2 + i] = if (((result >> @intCast(bit)) & 1) == 1) '1' else '0';
    }
    return @intCast(output_length);
}
