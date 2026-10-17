const MAX_LIST_LENGTH: usize = 64;
const MAX_INPUT_LENGTH: usize = 130;
const MAX_VALUE: i64 = 2_147_483_647;

export fn sublist_search(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_LENGTH) return -1;
    const main_count_value = values[0];
    const pattern_count_value = values[1];
    if (main_count_value < 0 or main_count_value > @as(i64, @intCast(MAX_LIST_LENGTH)) or
        pattern_count_value < 0 or pattern_count_value > @as(i64, @intCast(MAX_LIST_LENGTH))) return -1;
    const main_count: usize = @intCast(main_count_value);
    const pattern_count: usize = @intCast(pattern_count_value);
    if (length != 2 + main_count + pattern_count) return -1;
    for (0..main_count + pattern_count) |i| {
        const value = values[2 + i];
        if (value < 0 or value > MAX_VALUE) return -1;
    }

    if (main_count == 0 or pattern_count == 0 or pattern_count > main_count) return 0;
    const pattern_offset = 2 + main_count;
    for (0..main_count - pattern_count + 1) |start| {
        var matched: usize = 0;
        while (matched < pattern_count and values[2 + start + matched] == values[pattern_offset + matched]) : (matched += 1) {}
        if (matched == pattern_count) return 1;
    }
    return 0;
}
