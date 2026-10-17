const SPEED_OF_LIGHT: f64 = 299_792_458.0;
const SPEED_OF_LIGHT_MILLI: i64 = 299_792_458_000;
const MAX_LENGTH_TIME_MILLI: i64 = 1_000_000;
const MAX_INPUT_LENGTH: usize = 4;
const INVALID_RESULT: f64 = -1.0e300;

fn lorentz_gamma(velocity: f64) -> f64 {
    1.0 / (1.0 - velocity * velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT)).sqrt()
}

#[no_mangle]
pub unsafe extern "C" fn relativity(input: *const i64, length: usize) -> f64 {
    if input.is_null() || length < 3 || length > MAX_INPUT_LENGTH { return INVALID_RESULT; }
    let values = std::slice::from_raw_parts(input, length);
    let operation = values[0];
    let arg1_milli = values[1];
    let arg2_milli = values[2];
    if length != 3 { return INVALID_RESULT; }

    if operation == 0 {
        if arg2_milli != 0 || arg1_milli <= -SPEED_OF_LIGHT_MILLI || arg1_milli >= SPEED_OF_LIGHT_MILLI {
            return INVALID_RESULT;
        }
        return lorentz_gamma(arg1_milli as f64 / 1000.0);
    }
    if operation == 1 || operation == 2 {
        if arg1_milli < 0 || arg1_milli > MAX_LENGTH_TIME_MILLI ||
            arg2_milli <= -SPEED_OF_LIGHT_MILLI || arg2_milli >= SPEED_OF_LIGHT_MILLI {
            return INVALID_RESULT;
        }
        let quantity = arg1_milli as f64 / 1000.0;
        let velocity = arg2_milli as f64 / 1000.0;
        let gamma = lorentz_gamma(velocity);
        return if operation == 1 { quantity / gamma } else { quantity * gamma };
    }
    if operation == 3 {
        if arg1_milli < -SPEED_OF_LIGHT_MILLI || arg1_milli > SPEED_OF_LIGHT_MILLI ||
            arg2_milli <= -SPEED_OF_LIGHT_MILLI || arg2_milli >= SPEED_OF_LIGHT_MILLI {
            return INVALID_RESULT;
        }
        let velocity_one = arg1_milli as f64 / 1000.0;
        let frame_velocity = arg2_milli as f64 / 1000.0;
        return (velocity_one - frame_velocity) /
            (1.0 - velocity_one * frame_velocity / (SPEED_OF_LIGHT * SPEED_OF_LIGHT));
    }
    INVALID_RESULT
}
