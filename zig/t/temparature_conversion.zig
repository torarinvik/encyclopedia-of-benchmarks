const MAX_ABS_TEMPERATURE_MICRO: i64 = 1_000_000_000_000;
const MAX_INPUT_LENGTH: usize = 4;
const INVALID_RESULT: f64 = -1.0e300;

fn roundNearestTiesEven(value: f64) f64 {
    const lower = @floor(value);
    const fraction = value - lower;
    if (fraction < 0.5) return lower;
    if (fraction > 0.5) return lower + 1.0;
    const integer: i64 = @intFromFloat(lower);
    return if (@mod(integer, 2) == 0) lower else lower + 1.0;
}

fn roundDigits(value: f64, digits: i64) f64 {
    var scale: f64 = 1.0;
    const magnitude: i64 = if (digits < 0) -digits else digits;
    for (0..@as(usize, @intCast(magnitude))) |_| {
        scale *= 10.0;
    }
    const scaled = if (digits >= 0) value * scale else value / scale;
    const rounded = roundNearestTiesEven(scaled);
    return if (digits >= 0) rounded / scale else rounded * scale;
}

export fn temparature_conversion(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?;
    const operation = values[0];
    const temperature_micro = values[1];
    const digits = values[2];
    if (length != 3 or operation < 0 or operation > 5
        or temperature_micro < -MAX_ABS_TEMPERATURE_MICRO
        or temperature_micro > MAX_ABS_TEMPERATURE_MICRO
        or digits < -6 or digits > 6) return INVALID_RESULT;

    const temperature = @as(f64, @floatFromInt(temperature_micro)) / 1_000_000.0;
    const result = switch (operation) {
        0 => temperature * 1.8 + 32.0,
        1 => temperature + 273.15,
        2 => (temperature - 32.0) * 5.0 / 9.0,
        3 => (temperature - 32.0) * 5.0 / 9.0 + 273.15,
        4 => temperature - 273.15,
        5 => (temperature - 273.15) * 1.8 + 32.0,
        else => INVALID_RESULT,
    };
    return roundDigits(result, digits);
}
