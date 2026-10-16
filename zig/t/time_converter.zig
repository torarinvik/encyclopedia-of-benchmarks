const SCALE: i64 = 1_000_000;
const MAX_TIME_MICRO: i64 = 1_000_000_000;
const MAX_INPUT_LENGTH: usize = 4;
const INVALID_RESULT: f64 = -1.0e300;

fn seconds_per_unit(unit: i64) f64 {
    return switch (unit) {
        0 => 1.0,
        1 => 60.0,
        2 => 3600.0,
        3 => 86400.0,
        4 => 604800.0,
        5 => 2629800.0,
        6 => 31557600.0,
        else => 0.0,
    };
}

export fn time_converter(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const time_micro = values[0];
    const from_unit = values[1];
    const to_unit = values[2];
    if (time_micro < 0 or time_micro > MAX_TIME_MICRO or from_unit < 0 or from_unit > 6 or to_unit < 0 or to_unit > 6) return INVALID_RESULT;
    const time_value = @as(f64, @floatFromInt(time_micro)) / @as(f64, @floatFromInt(SCALE));
    const seconds_value = time_value * seconds_per_unit(from_unit);
    const converted = seconds_value / seconds_per_unit(to_unit);
    const rounded: i64 = @intFromFloat(converted * 1000.0 + 0.5);
    return @as(f64, @floatFromInt(rounded)) / 1000.0;
}
