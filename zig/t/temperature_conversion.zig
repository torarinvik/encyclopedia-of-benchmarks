const INVALID_RESULT: i64 = -9223372036854775807 - 1;

fn convertTemperature(operation: i64, value: f64) f64 {
    return switch (operation) {
        0 => (value * 9.0) / 5.0 + 32.0,
        1 => value + 273.15,
        2 => (value * 9.0) / 5.0 + 491.67,
        3 => ((value - 32.0) * 5.0) / 9.0,
        4 => ((value - 32.0) * 5.0) / 9.0 + 273.15,
        5 => value + 459.67,
        6 => value - 273.15,
        7 => ((value - 273.15) * 9.0) / 5.0 + 32.0,
        8 => (value * 9.0) / 5.0,
        9 => ((value - 491.67) * 5.0) / 9.0,
        10 => value - 459.67,
        11 => (value * 5.0) / 9.0,
        12 => value * 1.25,
        13 => value * 2.25 + 32.0,
        14 => value * 1.25 + 273.15,
        15 => value * 2.25 + 32.0 + 459.67,
        else => unreachable,
    };
}

export fn temperature_conversion(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const input = values.?[0..length];
    const operation = input[0];
    const temperature = input[1];
    if (operation < 0 or operation > 15 or temperature < -1000000 or temperature > 1000000) return INVALID_RESULT;
    const converted = convertTemperature(operation, @as(f64, @floatFromInt(temperature)));
    return @intFromFloat(@floor(converted + 0.5));
}
