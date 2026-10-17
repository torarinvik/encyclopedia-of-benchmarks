const MAX_INPUT_LENGTH: usize = 202;
const MAX_LIST_LENGTH: usize = 100;

fn writeI32Le(output: []u8, index: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    const offset = index * 4;
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn linkedlist_implentation_usingarray(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, output_capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    const operation_count = input[0];
    if (operation_count < 0 or operation_count > 100 or length != 1 + 2 * @as(usize, @intCast(operation_count))) return -1;

    var items: [MAX_LIST_LENGTH]i32 = [_]i32{0} ** MAX_LIST_LENGTH;
    var item_count: usize = 0;
    var cursor: usize = 1;
    for (0..@intCast(operation_count)) |_| {
        const opcode = input[cursor];
        const raw_value = input[cursor + 1];
        cursor += 2;
        if (raw_value < -2_147_483_648 or raw_value > 2_147_483_647 or item_count >= MAX_LIST_LENGTH) return -1;
        const value: i32 = @intCast(raw_value);
        if (opcode == 0) {
            var index = item_count;
            while (index > 0) : (index -= 1) items[index] = items[index - 1];
            items[0] = value;
            item_count += 1;
        } else if (opcode == 1) {
            if (item_count == 0) return -1;
            items[item_count] = value;
            item_count += 1;
        } else {
            return -1;
        }
    }

    const output_bytes = (item_count + 1) * 4;
    if (output_opt == null or output_capacity < output_bytes) return -2;
    const output = output_opt.?[0..output_bytes];
    writeI32Le(output, 0, @intCast(item_count));
    for (0..item_count) |index| writeI32Le(output, index + 1, items[index]);
    return @intCast(output_bytes);
}
