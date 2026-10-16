#[no_mangle]
pub unsafe extern "C" fn projectile_motion(
    values: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != 4 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }

    let velocity = values[0];
    let angle_degrees = values[1];
    let height = values[2];
    let gravity = values[3];
    if !(0.0..=1000.0).contains(&velocity)
        || !(-180.0..=180.0).contains(&angle_degrees)
        || !(0.0..=1000.0).contains(&height)
        || !(0.1..=20.0).contains(&gravity)
    {
        return -1;
    }

    let angle_radians = angle_degrees / 180.0 * std::f64::consts::PI;
    let initial_vertical_velocity = velocity * angle_radians.sin();
    let initial_horizontal_velocity = velocity * angle_radians.cos();
    let total_time_of_flight = (initial_vertical_velocity
        + (initial_vertical_velocity * initial_vertical_velocity + 2.0 * gravity * height).sqrt())
        / gravity;
    let maximum_height = if initial_vertical_velocity > 0.0 {
        let height_gained = initial_vertical_velocity * initial_vertical_velocity / (2.0 * gravity);
        height + height_gained
    } else {
        height
    };
    let horizontal_range = initial_horizontal_velocity * total_time_of_flight;

    if output.is_null() || capacity < 3 {
        return -2;
    }
    *output.add(0) = total_time_of_flight;
    *output.add(1) = horizontal_range;
    *output.add(2) = maximum_height;
    3
}
