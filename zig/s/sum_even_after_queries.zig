/// Apply updates in order and emit running even sums as little-endian i32s.
const MAX_NUMBERS: usize = 1000;
const MAX_QUERIES: usize = 1000;

export fn sum_even_after_queries(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 5 or length > 4002) return -1;
    const number_count_value = values[0];
    const query_count_value = values[1];
    if (number_count_value < 1 or number_count_value > MAX_NUMBERS or
        query_count_value < 1 or query_count_value > MAX_QUERIES) return -1;
    const number_count: usize = @intCast(number_count_value);
    const query_count: usize = @intCast(query_count_value);
    if (length != 2 + number_count + 2 * query_count) return -1;

    var working: [MAX_NUMBERS]i64 = undefined;
    var even_sum: i64 = 0;
    for (0..number_count) |index| {
        const value = values[2 + index];
        if (value < 1 or value > 1000) return -1;
        working[index] = value;
        if (@rem(value, 2) == 0) even_sum += value;
    }
    for (0..query_count) |query| {
        const offset = 2 + number_count + 2 * query;
        const delta = values[offset];
        const index = values[offset + 1];
        if (delta < -1000 or delta > 1000 or index < 0 or index >= number_count_value) return -1;
    }
    if (output_capacity < query_count * 4) return -2;

    for (0..query_count) |query| {
        const offset = 2 + number_count + 2 * query;
        const delta = values[offset];
        const index: usize = @intCast(values[offset + 1]);
        if (@rem(working[index], 2) == 0) even_sum -= working[index];
        working[index] += delta;
        if (@rem(working[index], 2) == 0) even_sum += working[index];
        const bits: u32 = @bitCast(@as(i32, @intCast(even_sum)));
        for (0..4) |byte| output[query * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(query_count);
}
