/// Return a spherical initial bearing in integer microdegrees.
#[no_mangle]
pub extern "C" fn bearing(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length != 4 {
        return -1;
    }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    let [latitude1_value, longitude1_value, latitude2_value, longitude2_value] =
        [values[0], values[1], values[2], values[3]];
    if !(-90_000_000..=90_000_000).contains(&latitude1_value)
        || !(-90_000_000..=90_000_000).contains(&latitude2_value)
        || !(-180_000_000..=180_000_000).contains(&longitude1_value)
        || !(-180_000_000..=180_000_000).contains(&longitude2_value)
        || (latitude1_value == latitude2_value && longitude1_value == longitude2_value)
    {
        return -1;
    }

    let radians_per_microdegree = 0.000001 * (std::f64::consts::PI / 180.0);
    let latitude1 = latitude1_value as f64 * radians_per_microdegree;
    let longitude1 = longitude1_value as f64 * radians_per_microdegree;
    let latitude2 = latitude2_value as f64 * radians_per_microdegree;
    let longitude2 = longitude2_value as f64 * radians_per_microdegree;
    let delta_longitude = longitude2 - longitude1;
    let east = delta_longitude.sin() * latitude2.cos();
    let north = latitude1.cos() * latitude2.sin()
        - latitude1.sin() * latitude2.cos() * delta_longitude.cos();
    let mut degrees = east.atan2(north).to_degrees();
    if degrees < 0.0 {
        degrees += 360.0;
    }
    let result = (degrees * 1_000_000.0 + 0.5) as i64;
    if result >= 360_000_000 { 0 } else { result }
}
