/// Emit the pinned default logarithmic-series expressions as ASCII lines.
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

fn hasNegativeSign(delta: i64, term: i64) bool {
    return (delta < 0 and term % 2 == 1) or (delta >= 0 and term % 2 == 0);
}

export fn logarithmic_series(values: [*c]const i64, length: usize,
                             output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 2) return -1;
    const x_value = values[0];
    const n_terms = values[1];
    if (x_value < -10 or x_value > 10 or n_terms < -64 or n_terms > 256) return -1;
    if (n_terms <= 0) return 0;
    const delta = x_value - 1;
    const base: u64 = @intCast(if (delta < 0) -delta else delta);
    var needed: usize = 0;
    const count: usize = @intCast(n_terms);
    for (1..count + 1) |term| {
        const prefix: usize = if (hasNegativeSign(delta, @intCast(term))) 2 else 1;
        needed += prefix + decimalWidth(base) + 2 * decimalWidth(term) + 4;
    }
    if (output == null or output_capacity < needed) return -2;
    var position: usize = 0;
    const out = output[0..output_capacity];
    for (1..count + 1) |term| {
        if (hasNegativeSign(delta, @intCast(term))) { out[position] = '-'; position += 1; }
        out[position] = '('; position += 1;
        position = appendDecimal(out.ptr, position, base);
        out[position] = '^'; position += 1;
        position = appendDecimal(out.ptr, position, term);
        out[position] = ')'; position += 1;
        out[position] = '/'; position += 1;
        position = appendDecimal(out.ptr, position, term);
        out[position] = '\n'; position += 1;
    }
    return @intCast(position);
}
