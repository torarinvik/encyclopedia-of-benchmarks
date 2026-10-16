const MAX_ABS_TEMPERATURE_MICRO: i64 = 1_000_000_000_000;
const MAX_INPUT_LENGTH: usize = 3;
const INVALID_RESULT: f64 = -1.0e300;

export fn temperature_converter(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const operation = values[0];
    const temperature_micro = values[1];
    if (temperature_micro < -MAX_ABS_TEMPERATURE_MICRO or temperature_micro > MAX_ABS_TEMPERATURE_MICRO)
        return INVALID_RESULT;
    const temperature = @as(f64, @floatFromInt(temperature_micro)) / 1_000_000.0;
    return switch (operation) {
        0 => temperature * 9.0 / 5.0 + 32.0,
        1 => temperature + 273.15,
        2 => (temperature - 32.0) * 5.0 / 9.0,
        3 => (temperature - 32.0) * 5.0 / 9.0 + 273.15,
        4 => temperature - 273.15,
        5 => (temperature - 273.15) * 9.0 / 5.0 + 32.0,
        else => INVALID_RESULT,
    };
}
