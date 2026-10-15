const MAX_ITEMS: i64 = 100_000;
const MAX_SAFE_INTEGER: i64 = 9_007_199_254_740_991;

/// Two-ended linear search with source-compatible endpoint priority.
export fn double_linear_search(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 100_002) return -1;
    const input = values[0..length];
    const target = input[0];
    const count_value = input[1];
    if (target < -MAX_SAFE_INTEGER or target > MAX_SAFE_INTEGER or
        count_value < 0 or count_value > MAX_ITEMS or
        length != @as(usize, @intCast(count_value)) + 2) return -1;
    const count: usize = @intCast(count_value);
    for (input[2..]) |value| {
        if (value < -MAX_SAFE_INTEGER or value > MAX_SAFE_INTEGER) return -1;
    }
    var start: usize = 0;
    var right = count;
    while (start < right) {
        if (input[start + 2] == target) return @intCast(start);
        if (input[right + 1] == target) return @intCast(right - 1);
        start += 1;
        right -= 1;
    }
    return -1;
}
