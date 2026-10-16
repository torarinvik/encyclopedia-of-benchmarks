export fn find_min_iterator(input: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > 129 or input == null) return -1;
    const values = input.?;
    if (values[0] < 0 or values[0] > 128 or length != @as(usize, @intCast(values[0])) + 1) return -1;
    const count: usize = @intCast(values[0]);
    if (count == 0) return -1;
    var minimum: i64 = 2_147_483_647;
    for (1..length) |i| {
        const value = values[i];
        if (value < 0 or value > 2_147_483_647) return -1;
        if (value < minimum) minimum = value;
    }
    return minimum;
}
