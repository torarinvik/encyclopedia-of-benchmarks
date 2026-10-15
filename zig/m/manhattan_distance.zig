/// Return the n-dimensional Manhattan distance between two integer points.
export fn manhattan_distance(values: [*]const i64, length: usize) f64 {
    if (length < 3) return -1.0e300;
    const dimensions = values[0];
    if (dimensions < 1 or dimensions > 16 or length != 1 + 2 * @as(usize, @intCast(dimensions))) return -1.0e300;
    var total: i64 = 0;
    var index: usize = 0;
    while (index < @as(usize, @intCast(dimensions))) : (index += 1) {
        const first = values[1 + index];
        const second = values[1 + @as(usize, @intCast(dimensions)) + index];
        if (first < -1_000_000 or first > 1_000_000 or second < -1_000_000 or second > 1_000_000)
            return -1.0e300;
        const difference = first - second;
        total += if (difference < 0) -difference else difference;
    }
    return @floatFromInt(total);
}
