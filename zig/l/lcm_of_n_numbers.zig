/// Fold a list of nonnegative values with overflow-safe Euclidean LCM.
export fn lcm_of_n_numbers(values: [*]const i64, length: usize) i64 {
    for (0..length) |index| {
        if (values[index] == 0) return 0;
    }
    var accumulator: u64 = 1;
    const maximum: u64 = 9223372036854775807;
    for (0..length) |index| {
        const value: u64 = @intCast(values[index]);
        var left = accumulator;
        var right = value;
        while (right != 0) {
            const remainder = left % right;
            left = right;
            right = remainder;
        }
        const reduced = accumulator / left;
        if (reduced > maximum / value) return -1;
        accumulator = reduced * value;
    }
    return @intCast(accumulator);
}
