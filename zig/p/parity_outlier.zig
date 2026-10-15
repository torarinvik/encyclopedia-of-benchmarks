pub export fn parity_outlier(values: [*]const i64, length: usize) i64 {
    if (length < 1 or values[0] < 3 or values[0] > 65 or @mod(values[0], 2) == 0) return -1;
    const count: usize = @intCast(values[0]);
    if (length != count + 1) return -1;
    var evens: usize = 0;
    var odds: usize = 0;
    var even_value: i64 = 0;
    var odd_value: i64 = 0;
    for (0..count) |i| {
        const value = values[i + 1];
        if (value < 0 or value > 2_147_483_647) return -1;
        if (@mod(value, 2) == 0) {
            evens += 1;
            even_value = value;
        } else {
            odds += 1;
            odd_value = value;
        }
    }
    if (evens == 1 and odds >= 2) return even_value;
    if (odds == 1 and evens >= 2) return odd_value;
    return -1;
}
