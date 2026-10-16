const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 129;
const MAX_OUTPUT_BYTES: usize = 1536;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn writeRecord(output: []u8, offset: usize, opcode: i64, tag: i64, value: i64) void {
    writeI64Le(output, offset, opcode);
    writeI64Le(output, offset + 8, tag);
    writeI64Le(output, offset + 16, value);
}

export fn stack_with_singly_linked_list(
    input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 0 or count_value > 64) return -1;
    const count: usize = @intCast(count_value);
    var opcodes: [MAX_OPERATIONS]i64 = @splat(0);
    var arguments: [MAX_OPERATIONS]i64 = @splat(0);
    var cursor: usize = 1;
    for (0..count) |i| {
        if (cursor >= length) return -1;
        const opcode = values[cursor];
        cursor += 1;
        opcodes[i] = opcode;
        if (opcode == 1) {
            if (cursor >= length) return -1;
            const value = values[cursor];
            cursor += 1;
            if (value < -2147483648 or value > 2147483647) return -1;
            arguments[i] = value;
        } else if (opcode < 2 or opcode > 5) return -1;
    }
    if (cursor != length) return -1;

    var node_values: [MAX_OPERATIONS + 1]i64 = @splat(0);
    var next_ids: [MAX_OPERATIONS + 1]usize = @splat(0);
    var node_count: usize = 0;
    var head: usize = 0;
    var buffer: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var written: usize = 0;
    for (0..count) |i| {
        const opcode = opcodes[i];
        var tag: i64 = 2;
        var value: i64 = 0;
        if (opcode == 1) {
            node_count += 1;
            node_values[node_count] = arguments[i];
            next_ids[node_count] = head;
            head = node_count;
        } else if (opcode == 2 or opcode == 3) {
            if (head == 0) {
                writeRecord(buffer[0..], written, opcode, 4, 2);
                written += 24;
                break;
            }
            tag = 0;
            value = node_values[head];
            if (opcode == 2) head = next_ids[head];
        } else if (opcode == 4) {
            head = 0;
        } else {
            tag = 0;
            var node = head;
            while (node != 0) : (node = next_ids[node]) value += 1;
        }
        writeRecord(buffer[0..], written, opcode, tag, value);
        written += 24;
    }
    if (output == null or capacity < written) return -2;
    for (0..written) |i| output.?[i] = buffer[i];
    return @intCast(written);
}
