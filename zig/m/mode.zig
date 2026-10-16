/// Find the unique mode of a bounded array of small nonnegative integers.
export fn mode(values: [*]const i64, length: usize) i64 {
    if (length == 0 or length > 4096) return -1;
    var counts: [256]usize = @splat(0);
    for (0..length) |index| {
        const value = values[index];
        if (value < 0 or value > 255) return -1;
        counts[@intCast(value)] += 1;
    }
    var maximum: usize = 0;
    var result: i64 = -1;
    var unique = true;
    for (counts, 0..) |count, value| {
        if (count > maximum) {
            maximum = count;
            result = @intCast(value);
            unique = true;
        } else if (count != 0 and count == maximum) {
            unique = false;
        }
    }
    return if (unique) result else -1;
}
