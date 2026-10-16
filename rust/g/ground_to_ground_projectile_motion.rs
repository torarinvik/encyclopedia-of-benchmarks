const INPUT_SCALE: i64 = 1_000_000;
const MAX_SPEED: i64 = 1_000_000_000;
const MAX_ANGLE: i64 = 360_000_000;
const MIN_GRAVITY: i64 = 1_000;
const MAX_GRAVITY: i64 = 100_000_000;
const MAX_TIME: i64 = 1_000_000_000;
const INVALID_RESULT: f64 = -1.0e300;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;

#[no_mangle]
pub unsafe extern "C" fn ground_to_ground_projectile_motion(
    values: *const i64, length: usize,
) -> f64 {
    if values.is_null() || length != 4 { return INVALID_RESULT; }
    let operation = *values;
    let speed_value = *values.add(1);
    let angle_value = *values.add(2);
    let auxiliary_value = *values.add(3);
    if operation < 0 || operation > 2 || speed_value < 0 || speed_value > MAX_SPEED ||
        angle_value < -MAX_ANGLE || angle_value > MAX_ANGLE { return INVALID_RESULT; }
    if operation == 1 {
        if auxiliary_value < 0 || auxiliary_value > MAX_TIME { return INVALID_RESULT; }
    } else if auxiliary_value < MIN_GRAVITY || auxiliary_value > MAX_GRAVITY {
        return INVALID_RESULT;
    }

    let speed = speed_value as f64 / INPUT_SCALE as f64;
    let angle = angle_value as f64 / INPUT_SCALE as f64;
    let radians = angle * (PI_VALUE / 180.0);
    let vertical_velocity = speed * radians.sin();
    if operation == 0 {
        let gravity = auxiliary_value as f64 / INPUT_SCALE as f64;
        return 2.0 * vertical_velocity / gravity;
    }
    if operation == 1 {
        let time = auxiliary_value as f64 / INPUT_SCALE as f64;
        return (speed * radians.cos()) * time;
    }
    let gravity = auxiliary_value as f64 / INPUT_SCALE as f64;
    vertical_velocity.powf(2.0) / (2.0 * gravity)
}
