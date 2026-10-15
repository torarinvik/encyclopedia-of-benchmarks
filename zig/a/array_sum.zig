/// Sum a bounded array of nonnegative signed integers.
export fn array_sum(values: [*]const i64, length: usize) i64 {
    if (length < 1) return -1;
    const count_value = values[0];
    if (count_value < 0 or count_value > 1024) return -1;
    const count: usize = @intCast(count_value);
    if (length != count + 1) return -1;
    var sum: i64 = 0;
    for (0..count) |i| {
        const value = values[i + 1];
        if (value < 0 or value > 1000000000) return -1;
        sum += value;
    }
    return sum;
}
