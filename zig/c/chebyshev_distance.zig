/// Return the greatest absolute coordinate difference from packed points.
export fn chebyshev_distance(values: [*]const i64, length: usize) i64 {
    if (length < 3) return -1;
    const dimension_value = values[0];
    if (dimension_value < 1 or dimension_value > 128) return -1;
    const dimension: usize = @intCast(dimension_value);
    if (length != 1 + 2 * dimension) return -1;
    var maximum: i64 = 0;
    for (0..dimension) |i| {
        const a = values[1 + i];
        const b = values[1 + dimension + i];
        if (a < -1_000_000_000 or a > 1_000_000_000 or b < -1_000_000_000 or b > 1_000_000_000) return -1;
        const difference = @abs(a - b);
        if (difference > maximum) maximum = difference;
    }
    return maximum;
}
