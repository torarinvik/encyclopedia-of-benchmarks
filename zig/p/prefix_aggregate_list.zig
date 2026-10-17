const MAX_INITIAL_VALUES: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_LIVE_VALUES: usize = 128;
const MAX_INPUT_LENGTH: usize = 258;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 260;
const MAX_OUTPUT_BYTES: usize = 512;
const MAX_VALUE: i64 = 1_000_000;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn prefix_aggregate_list(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const values = input.?;
    const initial_count_value = values[0];
    if (initial_count_value < 1 or initial_count_value > MAX_INITIAL_VALUES) return -1;
    const initial_count: usize = @intCast(initial_count_value);
    if (length < initial_count + 2) return -1;

    var prefix: [MAX_LIVE_VALUES]i64 = @splat(0);
    for (0..initial_count) |index| {
        const value = values[1 + index];
        if (value < -MAX_VALUE or value > MAX_VALUE) return -1;
        prefix[index] = value + (if (index == 0) 0 else prefix[index - 1]);
    }

    const operation_count_value = values[1 + initial_count];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    var live_count = initial_count;
    var cursor = initial_count + 2;
    var query_count: usize = 0;
    var encoded: [MAX_OUTPUT_BYTES]u8 = @splat(0);

    for (0..operation_count) |_| {
        if (cursor >= length) return -1;
        const operation = values[cursor];
        cursor += 1;
        if (operation == 0) {
            if (cursor >= length or live_count >= MAX_LIVE_VALUES) return -1;
            const value = values[cursor];
            cursor += 1;
            if (value < -MAX_VALUE or value > MAX_VALUE) return -1;
            prefix[live_count] = prefix[live_count - 1] + value;
            live_count += 1;
        } else if (operation == 1) {
            if (live_count <= 1) return -1;
            live_count -= 1;
        } else if (operation == 2) {
            if (cursor + 1 >= length) return -1;
            const range_from = values[cursor];
            const range_to = values[cursor + 1];
            cursor += 2;
            if (range_from < 1 or range_to < range_from or range_to > @as(i64, @intCast(live_count))) return -1;
            const from_index: usize = @intCast(range_from);
            const to_index: usize = @intCast(range_to);
            const result = prefix[to_index - 1] - (if (from_index == 1) 0 else prefix[from_index - 2]);
            storeI64Le(&encoded, 8 * query_count, result);
            query_count += 1;
        } else {
            return -1;
        }
    }

    if (cursor != length) return -1;
    const output_bytes = 8 * query_count;
    if (output == null or capacity < output_bytes) return -2;
    @memcpy(output.?[0..output_bytes], encoded[0..output_bytes]);
    return @intCast(output_bytes);
}
