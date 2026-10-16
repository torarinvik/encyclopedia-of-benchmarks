fn appendDecimal(out: [*]u8, position_input: usize, value_input: usize) usize {
    var value = value_input;
    var digits: [4]u8 = undefined;
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
        out[position] = '0' + digits[count];
        position += 1;
    }
    return position;
}

pub export fn harmonic_series(n: i64, output: [*c]u8, capacity: usize) i64 {
    if (n < -512 or n > 512) return -1;
    if (n <= 0) return 0;
    var needed: usize = 2;
    for (2..(@as(usize, @intCast(n)) + 1)) |term| {
        var value = term;
        var digits: usize = 0;
        while (true) {
            digits += 1;
            value /= 10;
            if (value == 0) break;
        }
        needed += digits + 3;
    }
    if (output == null or capacity < needed) return -2;
    var position: usize = 0;
    output[position] = '1'; position += 1;
    output[position] = '\n'; position += 1;
    const out = output[0..capacity];
    for (2..(@as(usize, @intCast(n)) + 1)) |term| {
        out[position] = '1'; position += 1;
        out[position] = '/'; position += 1;
        position = appendDecimal(out.ptr, position, term);
        out[position] = '\n'; position += 1;
    }
    return @intCast(position);
}
