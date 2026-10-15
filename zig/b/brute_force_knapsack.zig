fn solve(packed: []const i64, item_count: usize, capacity: i64) i64 {
    if (item_count == 0 or capacity == 0) return 0;
    const weight = packed[2 + 2 * (item_count - 1)];
    const value = packed[3 + 2 * (item_count - 1)];
    if (weight > capacity) return solve(packed, item_count - 1, capacity);
    const excluded = solve(packed, item_count - 1, capacity);
    const included = value + solve(packed, item_count - 1, capacity - weight);
    return @max(excluded, included);
}

export fn brute_force_knapsack(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > 30) return -1;
    const packed = values.?[0..length];
    const capacity = packed[0];
    const count_value = packed[1];
    if (capacity < 0 or capacity > 512 or count_value < 0 or count_value > 14) return -1;
    const item_count: usize = @intCast(count_value);
    if (length != 2 + 2 * item_count) return -1;
    for (0..item_count) |item| {
        const weight = packed[2 + 2 * item];
        const value = packed[3 + 2 * item];
        if (weight < 1 or weight > 4096 or value < 0 or value > 100000000) return -1;
    }
    return solve(packed, item_count, capacity);
}
