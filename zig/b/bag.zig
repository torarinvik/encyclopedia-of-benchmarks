const max_inserts: usize = 128;
const max_queries: usize = 64;

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

pub export fn bag(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2) return -1;
    const insert_count_value = input[0];
    if (insert_count_value < 0 or insert_count_value > 128) return -1;
    const insert_count: usize = @intCast(insert_count_value);
    if (length < insert_count + 2) return -1;
    const query_count_value = input[insert_count + 1];
    if (query_count_value < 0 or query_count_value > 64) return -1;
    const query_count: usize = @intCast(query_count_value);
    if (length != insert_count + query_count + 2) return -1;

    for (0..insert_count) |index| {
        const value = input[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
    }
    for (0..query_count) |query| {
        const value = input[insert_count + query + 2];
        if (value < -2147483648 or value > 2147483647) return -1;
    }
    const output_length = (query_count + 2) * 8;
    if (output == null or capacity < output_length) return -2;

    var values: [max_inserts]i64 = undefined;
    var distinct_count: usize = 0;
    for (0..insert_count) |index| {
        const value = input[index + 1];
        var node: usize = 0;
        while (node < distinct_count and values[node] != value) : (node += 1) {}
        if (node == distinct_count) {
            values[node] = value;
            distinct_count += 1;
        }
    }

    putI64Le(output, 0, insert_count_value);
    putI64Le(output, 8, if (insert_count == 0) 1 else 0);
    for (0..query_count) |query| {
        const target = input[insert_count + query + 2];
        var contains: i64 = 0;
        for (0..distinct_count) |node| {
            if (values[node] == target) contains = 1;
        }
        putI64Le(output, (query + 2) * 8, contains);
    }
    return @intCast(output_length);
}
