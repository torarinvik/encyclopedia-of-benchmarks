const MAX_OPERATIONS: usize = 256;
const MAX_INPUT_VALUES: usize = 1 + 2 * MAX_OPERATIONS;
const MAX_OUTPUT_BYTES: usize = (1 + 3 * MAX_OPERATIONS) * 8;

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn min_stack_using_two_stacks(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_INPUT_VALUES) return -1;
    const values = input.?[0..length];
    const count_value = values[0];
    if (count_value < 0 or count_value > 256) return -1;
    const count: usize = @intCast(count_value);

    var opcodes: [MAX_OPERATIONS]i64 = @splat(0);
    var operands: [MAX_OPERATIONS]i64 = @splat(0);
    var position: usize = 1;
    var event_count: usize = 0;
    for (0..count) |index| {
        if (position >= length) return -1;
        const opcode = values[position];
        position += 1;
        var operand: i64 = 0;
        if (opcode == 0) {
            if (position >= length) return -1;
            operand = values[position];
            position += 1;
            if (operand < -2_147_483_648 or operand > 2_147_483_647) return -1;
        } else if (opcode == 1 or opcode == 2 or opcode == 3) {
            event_count += 1;
        } else {
            return -1;
        }
        opcodes[index] = opcode;
        operands[index] = operand;
    }
    if (position != length) return -1;

    const needed = (1 + 3 * event_count) * 8;
    if (output == null or capacity < needed) return -2;

    var buffer: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    writeI64Le(buffer[0..], 0, @intCast(event_count));
    var stack: [MAX_OPERATIONS]i64 = @splat(0);
    var minima: [MAX_OPERATIONS]i64 = @splat(0);
    var depth: usize = 0;
    var minimum_depth: usize = 0;
    var record: usize = 1;
    for (0..count) |index| {
        const opcode = opcodes[index];
        if (opcode == 0) {
            const value = operands[index];
            stack[depth] = value;
            depth += 1;
            if (minimum_depth == 0 or value <= minima[minimum_depth - 1]) {
                minima[minimum_depth] = value;
                minimum_depth += 1;
            }
        } else if (opcode == 1) {
            var exception_flag: i64 = 0;
            if (depth == 0) {
                exception_flag = 1;
            } else {
                depth -= 1;
                if (stack[depth] == minima[minimum_depth - 1]) minimum_depth -= 1;
            }
            writeI64Le(buffer[0..], record * 8, 1);
            writeI64Le(buffer[0..], (record + 1) * 8, exception_flag);
            writeI64Le(buffer[0..], (record + 2) * 8, 0);
            record += 3;
        } else {
            var exception_flag: i64 = 0;
            var value: i64 = 0;
            if (depth == 0) {
                exception_flag = 1;
            } else if (opcode == 2) {
                value = stack[depth - 1];
            } else {
                value = minima[minimum_depth - 1];
            }
            writeI64Le(buffer[0..], record * 8, opcode);
            writeI64Le(buffer[0..], (record + 1) * 8, exception_flag);
            writeI64Le(buffer[0..], (record + 2) * 8, value);
            record += 3;
        }
    }
    for (0..needed) |index| output.?[index] = buffer[index];
    return @intCast(needed);
}
