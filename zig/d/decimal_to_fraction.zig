/// Convert a bounded exactly representable finite decimal to a reduced fraction.
const POWERS10 = [_]i64{ 1, 10, 100, 1000, 10000 };
const POWERS5 = [_]i64{ 1, 5, 25, 125, 625 };

fn gcdPositive(a_input: i64, b_input: i64) i64 {
    var a = a_input;
    var b = b_input;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @as(u6, @intCast(8 * byte)));
}

export fn decimal_to_fraction(values: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (length != 2) return -1;
    const mantissa = values[0];
    const places_value = values[1];
    if (places_value < 0 or places_value > 4) return -1;
    const places: usize = @intCast(places_value);
    const scale = POWERS10[places];
    const maximum_mantissa = 1_000_000 * scale;
    if (mantissa < -maximum_mantissa or mantissa > maximum_mantissa or @rem(mantissa, POWERS5[places]) != 0) return -1;
    if (capacity < 16) return -2;

    const decimal = @as(f64, @floatFromInt(mantissa)) / @as(f64, @floatFromInt(scale));
    var numerator: i64 = 0;
    var denominator: i64 = 1;
    if (decimal - @as(f64, @floatFromInt(@as(i64, @intFromFloat(decimal)))) == 0.0) {
        numerator = @intFromFloat(decimal);
    } else {
        var digits = places;
        var magnitude = if (mantissa < 0) -mantissa else mantissa;
        while (digits > 0 and @rem(magnitude, 10) == 0) {
            magnitude = @divTrunc(magnitude, 10);
            digits -= 1;
        }
        numerator = @intFromFloat(decimal * @as(f64, @floatFromInt(POWERS10[digits])));
        denominator = POWERS10[digits];
        const abs_numerator = if (numerator < 0) -numerator else numerator;
        const gcd = gcdPositive(abs_numerator, denominator);
        numerator = @divTrunc(numerator, gcd);
        denominator = @divTrunc(denominator, gcd);
    }
    storeI64Le(output, 0, numerator);
    storeI64Le(output, 8, denominator);
    return 16;
}
