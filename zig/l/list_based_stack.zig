const MAX_INITIAL_ITEMS: usize = 32;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 162;
const MAX_STACK_SIZE: usize = MAX_INITIAL_ITEMS + MAX_OPERATIONS;
const MAX_OUTPUT_BYTES: usize = 16 * MAX_OPERATIONS;

fn putI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn list_based_stack(
    input: ?[*]const i64,
    length: usize,
    output: ?[*]u8,
    capacity: usize,
) i64 {
    if (input == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const values = input.?[0..length];

    const raw_initial_count = values[0];
    if (raw_initial_count < 0 or raw_initial_count > 32) return -1;
    const initial_count: usize = @intCast(raw_initial_count);
    const operation_count_index = 1 + initial_count;
    if (operation_count_index >= length) return -1;

    var initial_items: [MAX_INITIAL_ITEMS]i64 = @splat(0);
    for (0..initial_count) |index| {
        const value = values[1 + index];
        if (value < -2147483648 or value > 2147483647) return -1;
        initial_items[index] = value;
    }

    const raw_operation_count = values[operation_count_index];
    if (raw_operation_count < 0 or raw_operation_count > 64) return -1;
    const operation_count: usize = @intCast(raw_operation_count);
    var opcodes: [MAX_OPERATIONS]i64 = @splat(0);
    var arguments: [MAX_OPERATIONS]i64 = @splat(0);
    var cursor = operation_count_index + 1;
    var validated_size = initial_count;
    for (0..operation_count) |index| {
        if (cursor >= length) return -1;
        const opcode = values[cursor];
        cursor += 1;
        opcodes[index] = opcode;
        if (opcode == 1 or opcode == 5) {
            if (cursor >= length) return -1;
            const value = values[cursor];
            cursor += 1;
            if (value < -2147483648 or value > 2147483647) return -1;
            arguments[index] = value;
            if (opcode == 1) validated_size += 1;
        } else if (opcode == 2 or opcode == 3) {
            if (validated_size == 0) return -1;
            if (opcode == 2) validated_size -= 1;
        } else if (opcode == 4) {
            // Count leaves the stack unchanged.
        } else if (opcode == 6) {
            validated_size = 0;
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    var stack: [MAX_STACK_SIZE]i64 = @splat(0);
    var stack_size = initial_count;
    for (0..initial_count) |index| stack[index] = initial_items[index];
    var buffer: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    var written: usize = 0;
    for (0..operation_count) |index| {
        const opcode = opcodes[index];
        var result: i64 = 0;
        if (opcode == 1) {
            stack[stack_size] = arguments[index];
            stack_size += 1;
        } else if (opcode == 2) {
            stack_size -= 1;
            result = stack[stack_size];
        } else if (opcode == 3) {
            result = stack[stack_size - 1];
        } else if (opcode == 4) {
            result = @intCast(stack_size);
        } else if (opcode == 5) {
            for (0..stack_size) |item| {
                if (stack[item] == arguments[index]) {
                    result = 1;
                    break;
                }
            }
        } else {
            stack_size = 0;
        }
        putI64Le(&buffer[0], written, opcode);
        putI64Le(&buffer[0], written + 8, result);
        written += 16;
    }

    if (output == null or capacity < written) return -2;
    const result = output.?;
    for (0..written) |index| result[index] = buffer[index];
    return @intCast(written);
}
