fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

/// Count literal-space-delimited words and requested-word matches.
export fn word_count(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 2 or length > 1050 or values[0] < 0 or values[0] > 999) return -1;
    const text_length: usize = @intCast(values[0]);
    const query_index = 1 + text_length;
    if (query_index >= length or values[query_index] < 0 or values[query_index] > 49) return -1;
    const query_length: usize = @intCast(values[query_index]);
    if (length != query_index + 1 + query_length) return -1;
    for (1..query_index) |index| {
        if (values[index] < 1 or values[index] > 127) return -1;
    }
    for (query_index + 1..length) |index| {
        if (values[index] < 1 or values[index] > 127) return -1;
    }
    var total: usize = 0;
    var matches: usize = 0;
    var start: usize = 0;
    for (0..text_length + 1) |finish| {
        if (finish == text_length or values[1 + finish] == 32) {
            const token_length = finish - start;
            if (token_length > 49) return -1;
            if (total >= 20) return -2;
            if (token_length == query_length) {
                var offset: usize = 0;
                while (offset < token_length and values[1 + start + offset] == values[query_index + 1 + offset]) : (offset += 1) {}
                if (offset == token_length) matches += 1;
            }
            total += 1;
            start = finish + 1;
        }
    }
    if (output_capacity < 16) return -2;
    storeI64Le(output, 0, @intCast(total));
    storeI64Le(output, 8, @intCast(matches));
    return 16;
}
