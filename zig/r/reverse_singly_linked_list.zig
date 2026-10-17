const MAX_LENGTH: usize = 256;

fn writeI32Le(output: []u8, index: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    const offset = index * 4;
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn reverse_singly_linked_list(values_opt: ?[*]const i32, length: usize, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (values_opt == null or length > MAX_LENGTH) return -1;
    const output_bytes = length * 4;
    if (output_opt == null or output_capacity < output_bytes) return -2;
    const values = values_opt.?;
    const output = output_opt.?[0..output_bytes];
    for (0..length) |index| {
        writeI32Le(output, index, values[length - 1 - index]);
    }
    return @intCast(output_bytes);
}
