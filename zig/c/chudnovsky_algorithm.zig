const max_precision: usize = 12;

fn sqrt10005() f64 {
    var root: f64 = 100.0;
    for (0..8) |_| root = 0.5 * (root + 10005.0 / root);
    return root;
}

export fn chudnovsky_algorithm(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length != 1 or values[0] < 1 or values[0] > max_precision) return -1;
    const precision: usize = @intCast(values[0]);
    const output_length = if (precision == 1) 0 else precision;
    if (capacity < output_length or (output_length > 0 and output == null)) return -2;
    if (precision == 1) return 0;

    const pi = (426880.0 * sqrt10005()) / 13591409.0;
    var fraction = pi - 3.0;
    output[0] = '3';
    output[1] = '.';
    for (0..precision - 2) |digit| {
        fraction *= 10.0;
        const next_digit: u8 = @intFromFloat(fraction);
        output[2 + digit] = '0' + next_digit;
        fraction -= @as(f64, @floatFromInt(next_digit));
    }
    return @intCast(output_length);
}
