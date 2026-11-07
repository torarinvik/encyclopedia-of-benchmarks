fn upper_bound_range(values: [*]const i64, target: i64, left: i64, right: i64) i64 {
    if (right <= left) return left;
    const middle = @divTrunc(left + right, 2);
    if (target < values[@intCast(middle + 1)])
        return upper_bound_range(values, target, left, middle);
    return upper_bound_range(values, target, middle + 1, right);
}

export fn upper_bound(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length == 0 or length > 513) return -1;
    const input_values = values.?;
    const target = input_values[0];
    if (target < -2147483648 or target > 2147483647) return -1;
    const array_length = length - 1;
    for (0..array_length) |index| {
        const value = input_values[index + 1];
        if (value < -2147483648 or value > 2147483647) return -1;
        if (index > 0 and input_values[index] > value) return -1;
    }
    return upper_bound_range(input_values, target, 0,
        @as(i64, @intCast(array_length)) - 1);
}
