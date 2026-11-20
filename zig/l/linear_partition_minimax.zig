fn feasible(input: [*c]const i64, n: usize, groups: usize, limit: i64) bool {
    var used_groups: usize = 1;
    var current_sum: i64 = 0;
    for (0..n) |i| {
        const value = input[i + 2];
        if (current_sum + value > limit) {
            used_groups += 1;
            current_sum = value;
            if (used_groups > groups) return false;
        } else {
            current_sum += value;
        }
    }
    return true;
}

export fn linear_partition_minimax(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > 35) return -1;
    if (input[0] < 1 or input[0] > 32 or input[1] < 1 or input[1] > input[0]) return -1;
    const n: usize = @intCast(input[0]);
    const groups: usize = @intCast(input[1]);
    if (length != n + 2) return -1;

    var low: i64 = 0;
    var upper: i64 = 0;
    for (0..n) |i| {
        const value = input[i + 2];
        if (value < 0 or value > 1000) return -1;
        if (value > low) low = value;
        upper += value;
    }
    while (low < upper) {
        const middle = low + @divTrunc(upper - low, 2);
        if (feasible(input, n, groups, middle)) upper = middle else low = middle + 1;
    }
    return low;
}
