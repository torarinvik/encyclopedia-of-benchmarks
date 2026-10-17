const MAX_INPUT_LENGTH: usize = 130;
const MAX_OPERATIONS: usize = 64;
const MAX_LIST_LENGTH: usize = 64;
const MAX_OUTPUT_FIELDS: usize = 194;

fn appendI64(records: *[MAX_OUTPUT_FIELDS]i64, count: *usize, value: i64) void {
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
    if (operation_count < 0 or operation_count > @as(i64, MAX_OPERATIONS)
        or input.len != 1 + 2 * @as(usize, @intCast(operation_count))) return null;

    var items: [MAX_LIST_LENGTH]i64 = [_]i64{0} ** MAX_LIST_LENGTH;
    var item_count: usize = 0;
    var record_count: usize = 0;
    var cursor: usize = 1;
    for (0..@intCast(operation_count)) |_| {
        const opcode = input[cursor];
        const value = input[cursor + 1];
        cursor += 2;
        if (value < -2147483648 or value > 2147483647) return null;
        if (opcode == 0) {
            if (item_count == MAX_LIST_LENGTH) return null;
            items[item_count] = value;
            item_count += 1;
            appendI64(records, &record_count, 0);
            appendI64(records, &record_count, 0);
        } else if (opcode == 1) {
            var found_at: usize = 0;
            while (found_at < item_count and items[found_at] != value) found_at += 1;
            const found: i64 = if (found_at < item_count) 1 else 0;
            appendI64(records, &record_count, 1);
            appendI64(records, &record_count, 1);
            appendI64(records, &record_count, found);
            if (found != 0 and found_at != 0) {
                var index = found_at;
                while (index > 0) {
                    items[index] = items[index - 1];
                    index -= 1;
                }
                items[0] = value;
            }
        } else {
            return null;
        }
    }
    appendI64(records, &record_count, 2);
    appendI64(records, &record_count, @intCast(item_count));
    for (items[0..item_count]) |value| appendI64(records, &record_count, value);
    return record_count;
}

export fn self_organizing_linked_list(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    var records: [MAX_OUTPUT_FIELDS]i64 = [_]i64{0} ** MAX_OUTPUT_FIELDS;
    const record_count = execute(input, &records) orelse return -1;
    const output_bytes = record_count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?[0..output_bytes];
    for (0..record_count) |index| writeI64Le(output, index * 8, records[index]);
    return @intCast(output_bytes);
}
