const MAX_INPUT_LENGTH: usize = 258;
const MAX_LIST_LENGTH: usize = 256;

fn writeI32Le(output: []u8, index: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    const offset = index * 4;
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn reverse_kgroup(input_opt: ?[*]const i32, length: usize, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    const group_size_value = input[0];
    const list_length = length - 1;
    if (group_size_value < 1 or group_size_value > 256 or list_length > MAX_LIST_LENGTH) return -1;
    const group_size: usize = @intCast(group_size_value);
    const output_bytes = list_length * 4;
    if (output_opt == null or output_capacity < output_bytes) return -2;
    const output = output_opt.?[0..output_bytes];
    var start: usize = 0;
    while (start + group_size <= list_length) {
        for (0..group_size) |offset|
            writeI32Le(output, start + offset, input[1 + start + group_size - 1 - offset]);
        start += group_size;
    }
    while (start < list_length) : (start += 1)
        writeI32Le(output, start, input[1 + start]);
    return @intCast(output_bytes);
}
