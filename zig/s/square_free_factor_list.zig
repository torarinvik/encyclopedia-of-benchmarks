/// Check that an integer factor list has no repeated values.
export fn square_free_factor_list(values: [*]const i64, length: usize) i64 {
    if (length > 256) return -1;
    for (0..length) |i| {
        const value = values[i];
        if (value < -2147483648 or value > 2147483647) return -1;
        for (0..i) |j| {
            if (value == values[j]) return 0;
        }
    }
    return 1;
}
