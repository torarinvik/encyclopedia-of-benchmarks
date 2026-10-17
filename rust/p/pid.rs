const MAX_INPUT_LENGTH: usize = 64;
const MAX_ERRORS: usize = 60;

#[no_mangle]
pub unsafe extern "C" fn pid(
    input: *const f64,
    length: usize,
    output: *mut f64,
    output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 5 || length > MAX_INPUT_LENGTH { return -1; }
    let error_count = length - 4;
    let values = std::slice::from_raw_parts(input, length);
    let (kp64, ki64, kd64, dt64) = (values[0], values[1], values[2], values[3]);
    if !kp64.is_finite() || !(-1.0..=1.0).contains(&kp64)
        || !ki64.is_finite() || !(-1.0..=1.0).contains(&ki64)
        || !kd64.is_finite() || !(-1.0..=1.0).contains(&kd64)
        || !dt64.is_finite() || !(dt64 == 0.0 || (0.01..=1.0).contains(&dt64))
        || error_count < 1 || error_count > MAX_ERRORS {
        return -1;
    }
    let mut errors = [0.0f32; MAX_ERRORS];
    for index in 0..error_count {
        let value = values[4 + index];
        if !value.is_finite() || !(-1.0..=1.0).contains(&value) { return -1; }
        errors[index] = value as f32;
    }
    if output.is_null() || output_capacity < error_count { return -2; }

    let (kp, ki, kd, dt) = (kp64 as f32, ki64 as f32, kd64 as f32, dt64 as f32);
    let (mut integral, mut last_error) = (0.0f32, 0.0f32);
    for index in 0..error_count {
        let error = errors[index];
        let proportional = error * kp;
        let mut integral_step = error * dt;
        integral_step = integral_step * ki;
        integral = integral + integral_step;
        let mut derivative = 0.0f32;
        if dt != 0.0 {
            let difference = error - last_error;
            let rate = difference / dt;
            derivative = rate * kd;
        }
        last_error = error;
        let partial = proportional + integral;
        let result = partial + derivative;
        *output.add(index) = result as f64;
    }
    error_count as i64
}
