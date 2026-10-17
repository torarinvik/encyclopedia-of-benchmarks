const SPEED_OF_LIGHT: f64 = 299_792_458.0;
const SPEED_OF_LIGHT_MILLI: i64 = 299_792_458_000;
const MAX_LENGTH_TIME_MILLI: i64 = 1_000_000;
const MAX_INPUT_LENGTH: usize = 4;
const INVALID_RESULT: f64 = -1.0e300;

fn lorentzGamma(velocity: f64) f64 {
    return 1.0 / @sqrt(1.0 - velocity * velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT));
}

export fn relativity(input: ?[*]const i64, length: usize) f64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const values = input.?[0..length];
    const operation = values[0];
    const arg1_milli = values[1];
    const arg2_milli = values[2];
    if (length != 3) return INVALID_RESULT;

    if (operation == 0) {
        if (arg2_milli != 0 or arg1_milli <= -SPEED_OF_LIGHT_MILLI or arg1_milli >= SPEED_OF_LIGHT_MILLI)
            return INVALID_RESULT;
        return lorentzGamma(@as(f64, @floatFromInt(arg1_milli)) / 1000.0);
    }
    if (operation == 1 or operation == 2) {
        if (arg1_milli < 0 or arg1_milli > MAX_LENGTH_TIME_MILLI or
            arg2_milli <= -SPEED_OF_LIGHT_MILLI or arg2_milli >= SPEED_OF_LIGHT_MILLI) return INVALID_RESULT;
        const quantity = @as(f64, @floatFromInt(arg1_milli)) / 1000.0;
        const velocity = @as(f64, @floatFromInt(arg2_milli)) / 1000.0;
        const gamma = lorentzGamma(velocity);
        return if (operation == 1) quantity / gamma else quantity * gamma;
    }
    if (operation == 3) {
        if (arg1_milli < -SPEED_OF_LIGHT_MILLI or arg1_milli > SPEED_OF_LIGHT_MILLI or
            arg2_milli <= -SPEED_OF_LIGHT_MILLI or arg2_milli >= SPEED_OF_LIGHT_MILLI) return INVALID_RESULT;
        const velocity_one = @as(f64, @floatFromInt(arg1_milli)) / 1000.0;
        const frame_velocity = @as(f64, @floatFromInt(arg2_milli)) / 1000.0;
        return (velocity_one - frame_velocity) /
            (1.0 - velocity_one * frame_velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT));
    }
    return INVALID_RESULT;
}
