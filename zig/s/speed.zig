const INVALID_RESULT: f64 = -1.0e300;
const MAX_SPEED_MICRO: i64 = 1_000_000_000_000_000;
const MAX_ROUNDED_MILLI: f64 = 9_007_199_254_740_992.0;
const TO_KMH = [_]f64{1.0, 3.6, 1.609344, 1.852, 1.09728, 1225.08, 1_079_252_848.8};
const FROM_KMH = [_]f64{1.0, 0.277777778, 0.621371192, 0.539956803,
                        0.911344415, 0.000816164, 9.265669311e-10};

fn roundThreeAway(scaled: f64) f64 {
    if (scaled == 0.0) return scaled / 1000.0;
    const negative = scaled < 0.0;
    const magnitude = if (negative) -scaled else scaled;
    var rounded_milli: u64 = @intFromFloat(magnitude);
    if (magnitude - @as(f64, @floatFromInt(rounded_milli)) >= 0.5) rounded_milli += 1;
    const rounded = @as(f64, @floatFromInt(rounded_milli)) / 1000.0;
    return if (negative) -rounded else rounded;
}

export fn speed(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 3) return INVALID_RESULT;
    const speed_micro = values[0];
    const from_unit = values[1];
    const to_unit = values[2];
    if (speed_micro < -MAX_SPEED_MICRO or speed_micro > MAX_SPEED_MICRO or
        from_unit < 0 or from_unit > 6 or to_unit < 0 or to_unit > 6) return INVALID_RESULT;
    const speed_value = @as(f64, @floatFromInt(speed_micro)) / 1_000_000.0;
    const kmh = speed_value * TO_KMH[@intCast(from_unit)];
    const result = kmh * FROM_KMH[@intCast(to_unit)];
    const scaled = result * 1000.0;
    if (scaled > MAX_ROUNDED_MILLI or scaled < -MAX_ROUNDED_MILLI) return INVALID_RESULT;
    return roundThreeAway(scaled);
}
