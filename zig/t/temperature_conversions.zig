const MAX_ABS_TEMPERATURE_MICRO: i64 = 1_000_000_000_000;
const MAX_INPUT_LENGTH: usize = 3;
const INVALID_RESULT: f64 = -1.0e300;

export fn temperature_conversions(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const operation = values[0];
    const micro = values[1];
    if (micro < -MAX_ABS_TEMPERATURE_MICRO or micro > MAX_ABS_TEMPERATURE_MICRO) return INVALID_RESULT;
    return switch (operation) {
        0 => if (@mod(micro, 5_000_000) == 0)
            @floatFromInt(9 * (@divTrunc(micro, 5_000_000)) + 32)
        else INVALID_RESULT,
        1 => if (@mod(micro - 32_000_000, 9_000_000) == 0)
            @floatFromInt(5 * (@divTrunc(micro - 32_000_000, 9_000_000)))
        else INVALID_RESULT,
        2 => if (@mod(micro, 1_000_000) == 0)
            @as(f64, @floatFromInt(@divTrunc(micro, 1_000_000))) + 273.15
        else INVALID_RESULT,
        3 => if (@mod(micro - 273_150_000, 1_000_000) == 0)
            @floatFromInt(@divTrunc(micro - 273_150_000, 1_000_000))
        else INVALID_RESULT,
        4 => if (@mod(micro - 273_150_000, 5_000_000) == 0)
            @floatFromInt(9 * (@divTrunc(micro - 273_150_000, 5_000_000)) + 32)
        else INVALID_RESULT,
        else => INVALID_RESULT,
    };
}
