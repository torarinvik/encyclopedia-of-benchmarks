const INVALID_RESULT: f64 = -1.0e300;

fn roundThreePython(value: f64) f64 {
    if (value == 0.0) return value;
    const negative = value < 0.0;
    var normalized = if (negative) -value else value;
    var exponent: i32 = 0;
    while (normalized >= 1.0) { normalized *= 0.5; exponent += 1; }
    while (normalized < 0.5) { normalized *= 2.0; exponent -= 1; }
    const significand: u64 = @intFromFloat(normalized * 9_007_199_254_740_992.0);
    const numerator = significand * 1000;
    const shift = 53 - exponent;
    var milliunits: u64 = 0;
    if (shift < 0) {
        const left_shift: u6 = @intCast(-shift);
        milliunits = numerator << left_shift;
    } else if (shift == 0) {
        milliunits = numerator;
    } else if (shift < 64) {
        const right_shift: u6 = @intCast(shift);
        const denominator: u64 = @as(u64, 1) << right_shift;
        milliunits = numerator >> right_shift;
        const remainder = numerator & (denominator - 1);
        const half = denominator >> 1;
        if (remainder > half or (remainder == half and (milliunits & 1) != 0)) milliunits += 1;
    }
    const rounded = @as(f64, @floatFromInt(milliunits)) / 1000.0;
    return if (negative) -rounded else rounded;
}

export fn charging_inductor(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 4) return INVALID_RESULT;
    const voltage_micro = values[0];
    const resistance_micro = values[1];
    const inductance_micro = values[2];
    const time_micro = values[3];
    if (voltage_micro < 1 or voltage_micro > 1_000_000_000_000 or
        resistance_micro < 10_000 or resistance_micro > 1_000_000_000_000_000 or
        inductance_micro < 1 or inductance_micro > 1_000_000_000_000 or
        time_micro < -1_000_000_000_000 or time_micro > 1_000_000_000_000) return INVALID_RESULT;
    const source_voltage = @as(f64, @floatFromInt(voltage_micro)) / 1_000_000.0;
    const resistance = @as(f64, @floatFromInt(resistance_micro)) / 1_000_000.0;
    const inductance = @as(f64, @floatFromInt(inductance_micro)) / 1_000_000.0;
    const time_sec = @as(f64, @floatFromInt(time_micro)) / 1_000_000.0;
    const exponent = (-time_sec * resistance) / inductance;
    if (exponent > 10.0) return INVALID_RESULT;
    return roundThreePython(source_voltage / resistance * (1.0 - @exp(exponent)));
}
