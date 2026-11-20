fn storeU64Le(output: []u8, offset: usize, value: u64) void {
    for (0..8) |byte| {
        const shift: u6 = @intCast(byte * 8);
        output[offset + byte] = @truncate(value >> shift);
    }
}

export fn van_der_corput_sequence(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length != 3) return -1;
    const values = input.?[0..3];
    const base = values[0];
    const first_index = values[1];
    const count = values[2];
    if (base < 2 or base > 16 or first_index < 1 or first_index > 4096
        or count < 0 or count > 128
        or (count > 0 and first_index + count - 1 > 4096)) return -1;

    const output_bytes: usize = @intCast(count * 16);
    if (output == null or output_capacity < output_bytes) return -2;
    const bytes = output.?[0..output_bytes];
    for (0..@intCast(count)) |offset| {
        var index = first_index + @as(i64, @intCast(offset));
        var numerator: u64 = 0;
        var denominator: u64 = 1;
        while (index > 0) {
            numerator = numerator * @as(u64, @intCast(base))
                + @as(u64, @intCast(@mod(index, base)));
            denominator *= @as(u64, @intCast(base));
            index = @divTrunc(index, base);
        }
        const position = offset * 16;
        storeU64Le(bytes, position, numerator);
        storeU64Le(bytes, position + 8, denominator);
    }
    return @intCast(output_bytes);
}
