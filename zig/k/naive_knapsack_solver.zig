export fn naive_knapsack_solver(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > 32) return -1;
    const capacity = values[0];
    const count = values[1];
    if (capacity < 0 or capacity > 1_000_000 or count < 0 or count > 30 or length != @as(usize, @intCast(count)) + 2) return -1;
    var weight: i64 = 0;
    var mask: i64 = 0;
    for (0..@as(usize, @intCast(count))) |i| {
        const item = values[i + 2];
        if (item < 0 or item > 1_000_000) return -1;
        if (weight + item <= capacity) { weight += item; mask |= @as(i64, 1) << @intCast(i); }
    }
    return mask;
}
