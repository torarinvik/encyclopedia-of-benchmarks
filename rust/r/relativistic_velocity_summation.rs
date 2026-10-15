const SPEED_OF_LIGHT: i64 = 299_792_458;
const INVALID_RESULT: f64 = -1.0e300;

#[no_mangle]
pub extern "C" fn relativistic_velocity_summation(values: *const i64, length: usize) -> f64 {
    if values.is_null() || length != 2 { return INVALID_RESULT; }
    let object_velocity = unsafe { *values };
    let frame_velocity = unsafe { *values.add(1) };
    if !(-SPEED_OF_LIGHT..=SPEED_OF_LIGHT).contains(&object_velocity) ||
        !(-(SPEED_OF_LIGHT - 1)..=SPEED_OF_LIGHT - 1).contains(&frame_velocity)
    {
        return INVALID_RESULT;
    }
    let numerator = object_velocity + frame_velocity;
    let c_squared = SPEED_OF_LIGHT * SPEED_OF_LIGHT;
    let denominator = 1.0 + (object_velocity * frame_velocity) as f64 / c_squared as f64;
    numerator as f64 / denominator
}
