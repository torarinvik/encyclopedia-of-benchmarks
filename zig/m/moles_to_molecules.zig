const invalid_result: f64 = -1.0e300;

fn parseScientificFour(value: f64) f64 {
    if (value == 0.0) return 0.0;
    var normalized = value;
    var decimal_exponent: i32 = 0;
    while (normalized >= 10.0) : (decimal_exponent += 1) { normalized /= 10.0; }
    while (normalized < 1.0) : (decimal_exponent -= 1) { normalized *= 10.0; }

    const bits: u64 = @bitCast(value);
    const fraction = bits & ((@as(u64, 1) << 52) - 1);
    const exponent_bits: i32 = @intCast((bits >> 52) & 0x7ff);
    const significand = (@as(u64, 1) << 52) | fraction;
    const binary_exponent = exponent_bits - 1023 - 52;
    const decimal_shift = decimal_exponent - 4;
    var denominator: u64 = 1;
    for (0..@intCast(decimal_shift)) |_| denominator *= 5;
    const binary_shift = binary_exponent - decimal_shift;
    var numerator = significand;
    if (binary_shift >= 0) numerator <<= @intCast(binary_shift) else denominator <<= @intCast(-binary_shift);
    var rounded = numerator / denominator;
    const remainder = numerator % denominator;
    if (remainder * 2 > denominator or (remainder * 2 == denominator and (rounded & 1) != 0)) rounded += 1;
    var decimal_scale: f64 = 1.0;
    for (0..@intCast(decimal_shift)) |_| decimal_scale *= 10.0;
    return @as(f64, @floatFromInt(rounded)) * decimal_scale;
}

export fn moles_to_molecules(input: [*c]const i64, length: usize) f64 {
    if (input == null or length != 1) return invalid_result;
    const moles_micro = input[0];
    if (moles_micro < 0 or moles_micro > 2000000) return invalid_result;
    const moles = @as(f64, @floatFromInt(moles_micro)) / 1000000.0;
    return parseScientificFour(moles * 6.022e23);
}
