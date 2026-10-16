const invalid_result: f64 = -1.0e300;
const max_particles: i64 = 64;
const max_coordinate_units: i64 = 1_000_000;
const max_mass_units: i64 = 1_000_000;

/// Round the exact binary64 input to cents, matching Python round(value, 2).
fn roundTwoPython(value: f64) f64 {
    if (value == 0.0) return value;
    const negative = value < 0.0;
    var normalized = if (negative) -value else value;
    var exponent: i32 = 0;
    while (normalized >= 1.0) { normalized *= 0.5; exponent += 1; }
    while (normalized < 0.5) { normalized *= 2.0; exponent -= 1; }
    const significand: u64 = @intFromFloat(normalized * 9_007_199_254_740_992.0);
    const numerator = significand * 100;
    const shift = 53 - exponent;
    var cents: u64 = 0;
    if (shift < 0) {
        const left_shift: u6 = @intCast(-shift);
        cents = numerator << left_shift;
    } else if (shift == 0) {
        cents = numerator;
    } else if (shift < 64) {
        const shift_usize: u6 = @intCast(shift);
        const denominator: u64 = @as(u64, 1) << shift_usize;
        cents = numerator >> shift_usize;
        const remainder = numerator & (denominator - 1);
        const half = denominator >> 1;
        if (remainder > half or (remainder == half and (cents & 1) != 0)) cents += 1;
    }
    const rounded = @as(f64, @floatFromInt(cents)) / 100.0;
    return if (negative) -rounded else rounded;
}

export fn center_of_mass(values: [*c]const i64, length: usize) f64 {
    if (values == null or length < 2 or length > 258) return invalid_result;
    const selector = values[0];
    const count_value = values[1];
    if (selector < 0 or selector > 2 or count_value < 1 or count_value > max_particles or
        length != 2 + 4 * @as(usize, @intCast(count_value))) return invalid_result;
    const count: usize = @intCast(count_value);
    for (0..count) |index| {
        const offset = 2 + 4 * index;
        for (0..3) |coordinate| {
            const unit = values[offset + coordinate];
            if (unit < -max_coordinate_units or unit > max_coordinate_units) return invalid_result;
        }
        const mass = values[offset + 3];
        if (mass < 1 or mass > max_mass_units) return invalid_result;
    }
    var total_mass: f64 = 0.0;
    for (0..count) |index| total_mass += @as(f64, @floatFromInt(values[2 + 4 * index + 3])) / 1000.0;
    var weighted_coordinate: f64 = 0.0;
    for (0..count) |index| {
        const offset = 2 + 4 * index;
        const coordinate = @as(f64, @floatFromInt(values[offset + @as(usize, @intCast(selector))])) / 1000.0;
        const mass = @as(f64, @floatFromInt(values[offset + 3])) / 1000.0;
        weighted_coordinate += coordinate * mass;
    }
    return roundTwoPython(weighted_coordinate / total_mass);
}
