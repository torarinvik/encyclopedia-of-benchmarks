/// Emit the bounded Python P-series list as newline-delimited ASCII.
fn decimalWidth(value_input: u64) usize {
    var value = value_input;
    var width: usize = 1;
    while (value >= 10) { value /= 10; width += 1; }
    return width;
}

fn appendDecimal(output: [*]u8, position_input: usize, value_input: u64) usize {
    var value = value_input;
    var digits: [20]u8 = undefined;
    var count: usize = 0;
    while (true) {
        digits[count] = @intCast(value % 10);
        count += 1;
        value /= 10;
        if (value == 0) break;
    }
    var position = position_input;
    while (count > 0) {
        count -= 1;
        output[position] = '0' + digits[count];
        position += 1;
    }
    return position;
}

export fn p_series(values: [*c]const i64, length: usize,
                   output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 2) return -1;
    const nth_term = values[0];
    const power = values[1];
    if (nth_term < -256 or nth_term > 256 or power < 0 or power > 7) return -1;
    if (nth_term <= 0) return 0;

    var needed: usize = 2;
    const count: usize = @intCast(nth_term);
    for (2..count + 1) |term| {
        var denominator: u64 = 1;
        for (0..@as(usize, @intCast(power))) |_| denominator *= term;
        needed += 5 + decimalWidth(denominator);
    }
    if (output == null or output_capacity < needed) return -2;

    var position: usize = 0;
    output[position] = '1'; position += 1;
    output[position] = '\n'; position += 1;
    const out = output[0..output_capacity];
    for (2..count + 1) |term| {
        var denominator: u64 = 1;
        for (0..@as(usize, @intCast(power))) |_| denominator *= term;
        out[position] = '1'; position += 1;
        out[position] = ' '; position += 1;
        out[position] = '/'; position += 1;
        out[position] = ' '; position += 1;
        position = appendDecimal(out.ptr, position, denominator);
        out[position] = '\n'; position += 1;
    }
    return @intCast(position);
}
