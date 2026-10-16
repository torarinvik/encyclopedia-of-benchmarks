/// Emit reduced proper fractions for one positive denominator.
fn gcd(left_input: u64, right_input: u64) u64 {
    var left = left_input;
    var right = right_input;
    while (right != 0) {
        const remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

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

export fn proper_fractions(values: [*c]const i64, length: usize,
                           output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 1) return -1;
    const denominator = values[0];
    if (denominator < 0 or denominator > 256) return -1;
    if (denominator <= 1) return 0;
    const unsigned_denominator: u64 = @intCast(denominator);
    var needed: usize = 0;
    for (1..unsigned_denominator) |numerator| {
        if (gcd(numerator, unsigned_denominator) == 1) {
            needed += decimalWidth(numerator) + decimalWidth(unsigned_denominator) + 2;
        }
    }
    if (output == null or output_capacity < needed) return -2;
    var position: usize = 0;
    const out = output[0..output_capacity];
    for (1..unsigned_denominator) |numerator| {
        if (gcd(numerator, unsigned_denominator) != 1) continue;
        position = appendDecimal(out.ptr, position, numerator);
        out[position] = '/'; position += 1;
        position = appendDecimal(out.ptr, position, unsigned_denominator);
        out[position] = '\n'; position += 1;
    }
    return @intCast(position);
}
