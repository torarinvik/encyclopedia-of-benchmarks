fn lower_bound_range(values: []const i64, target: i64, left: i64, right: i64) i64 {
    if (right <= left) return left;
    const middle = @divTrunc(left + right, 2);
    if (target == values[@intCast(middle)]) return middle;
    if (target < values[@intCast(middle)])
        return lower_bound_range(values, target, left, middle);
    return lower_bound_range(values, target, middle + 1, right);
}

export fn lower_bound(values: [*]const i64, length: usize, target: i64) i64 {
    if (length > 512 or target < -2147483648 or target > 2147483647) return -1;
    const slice = values[0..length];
    for (slice, 0..) |value, i| {
        if (value < -2147483648 or value > 2147483647) return -1;
        if (i > 0 and slice[i - 1] > value) return -1;
    }
    return lower_bound_range(slice, target, 0, @as(i64, @intCast(length)) - 1);
}
