fn storeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn alternative_list_arrange(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const values = input.?[0..length];
    if (values[0] < 0 or values[0] > 64) return -1;
    const a: usize = @intCast(values[0]);
    if (1 + a >= length or values[1 + a] < 0 or values[1 + a] > 64) return -1;
    const b: usize = @intCast(values[1 + a]);
    if (length != 2 + a + b) return -1;
    const count = a + b;
    if (count == 0) return 0;
    const required_bytes = count * 8;
    if (output == null or output_capacity < required_bytes) return -2;
    const result = output.?[0..output_capacity];
    var written: usize = 0;
    for (0..@max(a, b)) |i| {
        if (i < a) {
            storeI64Le(result, written * 8, values[1 + i]);
            written += 1;
        }
        if (i < b) {
            storeI64Le(result, written * 8, values[2 + a + i]);
            written += 1;
        }
    }
    return @intCast(count);
}
