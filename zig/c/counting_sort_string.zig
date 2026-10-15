const MAX_TEXT_LENGTH: i64 = 4095;

/// Portable byte counting sort for printable non-space ASCII characters.
export fn counting_sort_string(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 1 or length > 4096) return -1;
    const count = values[0];
    if (count < 0 or count > MAX_TEXT_LENGTH or length != @as(usize, @intCast(count)) + 1) return -1;

    var frequencies: [256]usize = @splat(0);
    for (0..@intCast(count)) |index| {
        const value = values[index + 1];
        if (value < 33 or value > 126) return -1;
        frequencies[@intCast(value)] += 1;
    }
    if (output == null or output_capacity < @as(usize, @intCast(count))) return -2;

    for (1..256) |value| frequencies[value] += frequencies[value - 1];
    var index: usize = @intCast(count);
    while (index > 0) {
        const value: usize = @intCast(values[index]);
        frequencies[value] -= 1;
        output[frequencies[value]] = @intCast(value);
        index -= 1;
    }
    return count;
}
