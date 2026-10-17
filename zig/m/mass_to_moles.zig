const invalid_result: f64 = -1.0e300;

fn roundBinary64ToHundredth(value: f64) f64 {
    if (value == 0.0) return 0.0;
    const bits: u64 = @bitCast(value);
    const fraction = bits & ((@as(u64, 1) << 52) - 1);
    const exponent_bits: i32 = @intCast((bits >> 52) & 0x7ff);
    const significand = (@as(u64, 1) << 52) | fraction;
    const binary_exponent = exponent_bits - 1023 - 52;
    const shift: u6 = @intCast(-binary_exponent);
    const scaled_significand = significand * 100;
    const denominator = @as(u64, 1) << shift;
    var hundredths = scaled_significand >> shift;
    const remainder = scaled_significand & (denominator - 1);
    const halfway = denominator >> 1;
    if (remainder > halfway or (remainder == halfway and hundredths & 1 != 0)) hundredths += 1;
    return @as(f64, @floatFromInt(hundredths)) / 100.0;
}

export fn mass_to_moles(input: [*c]const i64, length: usize) f64 {
    if (input == null or length != 2) return invalid_result;
    const mass = input[0];
    const molar_mass = input[1];
    if (mass < 0 or mass > 1000 or molar_mass < 1 or molar_mass > 1000) return invalid_result;
    return roundBinary64ToHundredth(@as(f64, @floatFromInt(mass)) / @as(f64, @floatFromInt(molar_mass)));
}
