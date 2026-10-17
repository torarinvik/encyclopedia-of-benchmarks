const MAX_INPUT_LENGTH: usize = 98;
const MAX_OUTPUT_FIELDS: usize = 594;

fn append(records: *[MAX_OUTPUT_FIELDS]i64, count: *usize, value: i64) void {
    records[count.*] = value;
    count.* += 1;
}

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn execute(input: []const i64, records: *[MAX_OUTPUT_FIELDS]i64) ?usize {
    if (input.len < 1 or input.len > MAX_INPUT_LENGTH) return null;
    const operation_count = input[0];
    if (operation_count < 0 or operation_count > 32 or input.len != 1 + 3 * @as(usize, @intCast(operation_count))) return null;
    var items: [64]i64 = [_]i64{0} ** 64;
    var head: usize = 32;
    var item_count: usize = 0;
    var record_count: usize = 0;
    var cursor: usize = 1;
    for (0..@intCast(operation_count)) |_| {
        const opcode = input[cursor];
        const arg1 = input[cursor + 1];
        const arg2 = input[cursor + 2];
        cursor += 3;
        switch (opcode) {
            0, 1 => {
                if (arg1 < -1_000_000 or arg1 > 1_000_000 or arg2 != 0 or item_count >= 32) return null;
                if (opcode == 0) { head -= 1; items[head] = arg1; } else { items[head + item_count] = arg1; }
                item_count += 1;
                append(records, &record_count, opcode); append(records, &record_count, 0);
            },
            2 => {
                if (arg1 != 0 or arg2 != 0) return null;
                append(records, &record_count, opcode);
                if (item_count == 0) append(records, &record_count, 0) else { append(records, &record_count, 1); append(records, &record_count, items[head]); head += 1; item_count -= 1; }
            },
            3 => {
                if (arg1 != 0 or arg2 != 0) return null;
                append(records, &record_count, opcode);
                if (item_count == 0) append(records, &record_count, 0) else { append(records, &record_count, 1); item_count -= 1; append(records, &record_count, items[head + item_count]); }
            },
            4, 5 => {
                if (arg1 != 0 or arg2 != 0) return null;
                append(records, &record_count, opcode);
                if (item_count == 0) append(records, &record_count, 0) else { append(records, &record_count, 1); append(records, &record_count, if (opcode == 4) items[head] else items[head + item_count - 1]); }
            },
            6 => {
                if (arg2 != 0 or arg1 < 1 or arg1 > @as(i64, @intCast(item_count))) return null;
                append(records, &record_count, opcode); append(records, &record_count, 1); append(records, &record_count, items[head + @as(usize, @intCast(arg1)) - 1]);
            },
            7 => {
                if (arg1 < 1 or arg1 > @as(i64, @intCast(item_count)) or arg2 < -1_000_000 or arg2 > 1_000_000) return null;
                items[head + @as(usize, @intCast(arg1)) - 1] = arg2;
                append(records, &record_count, opcode); append(records, &record_count, 0);
            },
            8 => {
                if (arg1 < -1 or arg1 > 33 or arg2 != 0) return null;
                append(records, &record_count, opcode); append(records, &record_count, 1); append(records, &record_count, if (arg1 >= 1 and arg1 <= @as(i64, @intCast(item_count))) 1 else 0);
            },
            9 => {
                if (arg1 != 0 or arg2 != 0) return null;
                append(records, &record_count, opcode); append(records, &record_count, 1); append(records, &record_count, @intCast(item_count));
            },
            10, 11 => {
                if (arg1 != 0 or arg2 != 0) return null;
                append(records, &record_count, opcode); append(records, &record_count, @intCast(item_count));
                for (0..item_count) |offset| {
                    const logical = if (opcode == 10) offset + 1 else item_count - offset;
                    append(records, &record_count, @intCast(logical)); append(records, &record_count, items[head + logical - 1]);
                }
            },
            else => return null,
        }
    }
    append(records, &record_count, 12); append(records, &record_count, @intCast(item_count));
    for (0..item_count) |offset| append(records, &record_count, items[head + offset]);
    return record_count;
}

export fn table_list(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    var records: [MAX_OUTPUT_FIELDS]i64 = [_]i64{0} ** MAX_OUTPUT_FIELDS;
    const count = execute(input, &records) orelse return -1;
    const bytes = count * 8;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?[0..bytes];
    for (0..count) |index| writeI64Le(output, index * 8, records[index]);
    return @intCast(bytes);
}
