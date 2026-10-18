/// Collision-free integer-set membership for the shared hash-table contract.
const TABLE_CAPACITY: usize = 17;
const MAX_INSERT_COUNT: i64 = 8;
const MAX_QUERY_COUNT: i64 = 8;
const MAX_KEY: i64 = 1000;
const MAX_PARSEABLE_LENGTH: usize = 19;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
    }
}

export fn hash_table(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > MAX_PARSEABLE_LENGTH) return -1;
    const raw_insert_count = values[0];
    if (raw_insert_count < 0 or raw_insert_count > MAX_INSERT_COUNT) return -1;
    const insert_count: usize = @intCast(raw_insert_count);
    const query_count_index = 1 + insert_count;
    if (query_count_index >= length) return -1;
    const raw_query_count = values[query_count_index];
    if (raw_query_count < 1 or raw_query_count > MAX_QUERY_COUNT) return -1;
    const query_count: usize = @intCast(raw_query_count);
    const query_start = query_count_index + 1;
    const total_keys = insert_count + query_count;
    if (length != query_start + query_count) return -1;

    for (0..total_keys) |index| {
        const position = if (index < insert_count) 1 + index else query_start + index - insert_count;
        const key = values[position];
        if (key < 1 or key > MAX_KEY) return -1;
        for (0..index) |prior| {
            const prior_position = if (prior < insert_count) 1 + prior else query_start + prior - insert_count;
            const other = values[prior_position];
            const same_group = (index < insert_count) == (prior < insert_count);
            if (key == other) {
                if (same_group) return -1;
            } else if (@rem(key, TABLE_CAPACITY) == @rem(other, TABLE_CAPACITY) or
                       @rem(key, 3000) == @rem(other, 3000)) {
                return -1;
            }
        }
    }

    var table: [TABLE_CAPACITY]i64 = @splat(0);
    for (0..insert_count) |index| {
        const key = values[1 + index];
        table[@intCast(@rem(key, TABLE_CAPACITY))] = key;
    }

    const output_bytes = 8 * query_count;
    if (output == null or output_capacity < output_bytes) return -2;
    for (0..query_count) |index| {
        const query = values[query_start + index];
        const found: i64 = if (table[@intCast(@rem(query, TABLE_CAPACITY))] == query) 1 else 0;
        storeI64Le(output, 8 * index, found);
    }
    return @intCast(output_bytes);
}
