const MAX_CAPACITY: i64 = 512;
const MAX_ITEMS: i64 = 16;
const MAX_WEIGHT: i64 = 4096;
const MAX_VALUE: i64 = 1_000_000_000;

fn solve(items_data: []const i64, item_count: i64, capacity: i64) i64 {
    if (item_count == 0 or capacity == 0) return 0;
    const offset: usize = @intCast(2 + 2 * (item_count - 1));
    const weight = items_data[offset];
    const value = items_data[offset + 1];
    if (weight <= capacity) {
        const take = value + solve(items_data, item_count - 1, capacity - weight);
        const skip = solve(items_data, item_count - 1, capacity);
        return @max(take, skip);
    }
    return solve(items_data, item_count - 1, capacity);
}

export fn knapsack_01_recursive_benchmark(items_data: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 34) return -1;
    const values = items_data[0..length];
    const capacity = values[0];
    const item_count = values[1];
    if (capacity < 0 or capacity > MAX_CAPACITY or item_count < 0 or item_count > MAX_ITEMS
        or length != 2 + 2 * @as(usize, @intCast(item_count))) return -1;
    for (0..@intCast(item_count)) |item| {
        const offset = 2 + 2 * item;
        const weight = values[offset];
        const value = values[offset + 1];
        if (weight < 1 or weight > MAX_WEIGHT or value < 0 or value > MAX_VALUE) return -1;
    }
    return solve(values, item_count, capacity);
}
