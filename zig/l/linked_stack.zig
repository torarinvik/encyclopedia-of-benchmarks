const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 129;
const MAX_OUTPUT_BYTES: usize = 1536;

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn putRecord(output: [*]u8, offset: usize, opcode: i64, tag: i64, value: i64) void {
    putI64Le(output, offset, opcode);
    putI64Le(output, offset + 8, tag);
    putI64Le(output, offset + 16, value);
}

export fn linked_stack(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];
    const raw_count = values[0];
    if (raw_count < 0 or raw_count > 64) return -1;
    const operation_count: usize = @intCast(raw_count);
    var opcodes: [MAX_OPERATIONS]i64 = @splat(0);
    var arguments: [MAX_OPERATIONS]i64 = @splat(0);
    var cursor: usize = 1;
    for (0..operation_count) |index| {
        if (cursor >= length) return -1;
        const opcode = values[cursor];
        cursor += 1;
        opcodes[index] = opcode;
        if (opcode == 1) {
            if (cursor >= length) return -1;
            const value = values[cursor];
            cursor += 1;
            if (value < -2147483648 or value > 2147483647) return -1;
            arguments[index] = value;
        } else if (opcode < 2 or opcode > 4) return -1;
    }
    if (cursor != length) return -1;

    var node_values: [MAX_OPERATIONS + 1]i64 = @splat(0);
    var below: [MAX_OPERATIONS + 1]usize = @splat(0);
    var node_count: usize = 0;
    var head: usize = 0;
    var buffer: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var written: usize = 0;
    for (0..operation_count) |index| {
        const opcode = opcodes[index];
        var tag: i64 = 2;
        var value: i64 = 0;
        if (opcode == 1) {
            node_count += 1;
            node_values[node_count] = arguments[index];
            below[node_count] = head;
            head = node_count;
        } else if (opcode == 2) {
            if (head != 0) {
                tag = 0;
                value = node_values[head];
            }
        } else if (opcode == 3) {
            if (head != 0) {
                tag = 0;
                value = node_values[head];
                head = below[head];
            }
        } else {
            tag = 1;
            value = if (head == 0) 1 else 0;
        }
        putRecord(&buffer[0], written, opcode, tag, value);
        written += 24;
    }

    if (output == null or capacity < written) return -2;
    const result = output.?;
    for (0..written) |index| result[index] = buffer[index];
    return @intCast(written);
}
