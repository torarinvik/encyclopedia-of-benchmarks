/// Bottom-up 0/1 knapsack using one row and descending capacities.
export fn knapsack_zero_one_tabulation(input_values: [*c]const i64, length: usize) i64 {
    if (input_values == null) return -1;
    if (length < 2 or length > 258) return -1;
    if (input_values[0] < 0 or input_values[0] > 512 or input_values[1] < 0 or input_values[1] > 128) return -1;
    const capacity: usize = @intCast(input_values[0]);
    const item_count: usize = @intCast(input_values[1]);
    if (length != 2 + 2 * item_count) return -1;
    for (0..item_count) |item| {
        const weight = input_values[2 + 2 * item];
        const value = input_values[3 + 2 * item];
        if (weight < 1 or weight > 4096 or value < 0 or value > 1000000000) return -1;
    }

    var dp: [513]i64 = @splat(0);
    const width = capacity + 1;
    const steps = item_count * width;
    for (0..steps) |step| {
        const item = step / width;
        const current_capacity = capacity - step % width;
        const weight: usize = @intCast(input_values[2 + 2 * item]);
        const value = input_values[3 + 2 * item];
        if (weight <= current_capacity) {
            const candidate = dp[current_capacity - weight] + value;
            if (candidate > dp[current_capacity]) dp[current_capacity] = candidate;
        }
    }
    return dp[capacity];
}
