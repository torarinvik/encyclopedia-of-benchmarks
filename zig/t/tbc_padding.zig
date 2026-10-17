const MAX_BYTES: usize = 256;
const MAX_INPUT_VALUES: usize = MAX_BYTES + 3;

fn writeI64Le(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> (8 * byte));
}

export fn tbc_padding(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];
    const operation = values[0];
    const offset_value = values[1];
    const count_value = values[2];
    if (operation < 0 or operation > 2 or count_value < 0 or count_value > MAX_BYTES or
        length != @as(usize, @intCast(count_value)) + 3) return -1;
    const count: usize = @intCast(count_value);
    if ((operation == 0 and (count == 0 or offset_value < 0 or offset_value > count_value)) or
        (operation != 0 and offset_value != 0) or (operation == 2 and count == 0)) return -1;
    for (values[3..]) |value| if (value < 0 or value > 255) return -1;

    if (operation == 0) {
        const offset: usize = @intCast(offset_value);
        const previous = values[if (offset > 0) offset + 2 else count + 2];
        const code: u8 = if ((previous & 1) == 0) 0xff else 0x00;
        const needed = 8 + count;
        if (output == null or capacity < needed) return -2;
        writeI64Le(output.?, 0, @intCast(count - offset));
        for (0..count) |index| output.?[8 + index] = if (index >= offset) code else @intCast(values[3 + index]);
        return @intCast(needed);
    }
    if (operation == 1) {
        var survivors = count;
        if (count > 0) {
            const code: i64 = if ((values[2 + count] & 1) == 0) 0 else 255;
            while (survivors > 0 and values[2 + survivors] == code) survivors -= 1;
        }
        if (output == null or capacity < survivors) return -2;
        for (0..survivors) |index| output.?[index] = @intCast(values[3 + index]);
        return @intCast(survivors);
    }
    const terminal = values[2 + count];
    if (terminal != 0 and terminal != 255) return -1;
    var padding_count: usize = 0;
    while (padding_count < count and values[2 + count - padding_count] == terminal) padding_count += 1;
    if (output == null or capacity < 8) return -2;
    writeI64Le(output.?, 0, @intCast(padding_count));
    return 8;
}
