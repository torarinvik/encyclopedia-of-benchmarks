const MAX_INPUT_LENGTH: usize = 99;
const MAX_OPERATIONS: usize = 32;
const MAX_CAPACITY: usize = 16;
const MAX_OUTPUT_FIELDS: usize = 114;

fn append(records: *[MAX_OUTPUT_FIELDS]i64, count: *usize, value: i64) void {
    records[count.*] = value;
    count.* += 1;
}

fn writeI64Le(output: []u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn execute(input: []const i64, records: *[MAX_OUTPUT_FIELDS]i64) ?usize {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const capacity_value = input[0];
    const operation_count = input[1];
    if (capacity_value < 2 or capacity_value > @as(i64, MAX_CAPACITY)
        or operation_count < 0 or operation_count > @as(i64, MAX_OPERATIONS)
        or input.len != 2 + 3 * @as(usize, @intCast(operation_count))) return null;
    const capacity: usize = @intCast(capacity_value);
    var keys: [MAX_CAPACITY]i64 = [_]i64{0} ** MAX_CAPACITY;
    var values: [MAX_CAPACITY]i64 = [_]i64{0} ** MAX_CAPACITY;
    var seen: [MAX_OPERATIONS]i64 = [_]i64{0} ** MAX_OPERATIONS;
    var order: [MAX_CAPACITY]usize = [_]usize{0} ** MAX_CAPACITY;
    var cache_count: usize = 0;
    var seen_count: usize = 0;
    var record_count: usize = 0;
    var cursor: usize = 2;
    for (0..@intCast(operation_count)) |_| {
        const opcode = input[cursor];
        const key = input[cursor + 1];
        const value = input[cursor + 2];
        cursor += 3;
        if (key < -1_000_000 or key > 1_000_000) return null;
        if (opcode == 0) {
            if (value < -1_000_000 or value > 1_000_000) return null;
            for (seen[0..seen_count]) |prior| if (prior == key) return null;
            seen[seen_count] = key;
            seen_count += 1;
            var slot: usize = cache_count;
            if (cache_count == capacity) {
                slot = order[0];
                for (0..(cache_count - 1)) |index| order[index] = order[index + 1];
                cache_count -= 1;
            }
            keys[slot] = key;
            values[slot] = value;
            order[cache_count] = slot;
            cache_count += 1;
            append(records, &record_count, 0);
            append(records, &record_count, 0);
        } else if (opcode == 1) {
            if (value != 0) return null;
            var position: usize = 0;
            while (position < cache_count and keys[order[position]] != key) position += 1;
            if (position == cache_count) return null;
            const slot = order[position];
            const cached_value = values[slot];
            for (position..(cache_count - 1)) |index| order[index] = order[index + 1];
            order[cache_count - 1] = slot;
            append(records, &record_count, 1);
            append(records, &record_count, 1);
            append(records, &record_count, cached_value);
        } else {
            return null;
        }
    }
    append(records, &record_count, 2);
    append(records, &record_count, @intCast(cache_count));
    for (order[0..cache_count]) |slot| {
        append(records, &record_count, keys[slot]);
        append(records, &record_count, values[slot]);
    }
    return record_count;
}

export fn lru(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const input = input_opt.?[0..length];
    var records: [MAX_OUTPUT_FIELDS]i64 = [_]i64{0} ** MAX_OUTPUT_FIELDS;
    const record_count = execute(input, &records) orelse return -1;
    const output_bytes = record_count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?[0..output_bytes];
    for (0..record_count) |index| writeI64Le(output, index * 8, records[index]);
    return @intCast(output_bytes);
}
