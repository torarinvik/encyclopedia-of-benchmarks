const INVALID_RESULT: f64 = -1.0e300;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;

fn valid_coordinates(values: *const i64, length: usize) -> bool {
    if values.is_null() || length != 4 { return false; }
    let values = unsafe { std::slice::from_raw_parts(values, length) };
    if values[0] < -90000000 || values[0] > 90000000 { return false; }
    if values[2] < -90000000 || values[2] > 90000000 { return false; }
    if values[1] < -180000000 || values[1] > 180000000 { return false; }
    if values[3] < -180000000 || values[3] > 180000000 { return false; }
    true
}

fn haversine_a(values: *const i64) -> f64 {
    let values = unsafe { std::slice::from_raw_parts(values, 4) };
    let radians_per_microdegree = PI_VALUE / 180000000.0;
    let latitude1 = values[0] as f64 * radians_per_microdegree;
    let longitude1 = values[1] as f64 * radians_per_microdegree;
    let latitude2 = values[2] as f64 * radians_per_microdegree;
    let longitude2 = values[3] as f64 * radians_per_microdegree;
    let delta_latitude = latitude2 - latitude1;
    let delta_longitude = longitude2 - longitude1;
    let sin_latitude = (delta_latitude / 2.0).sin();
    let sin_longitude = (delta_longitude / 2.0).sin();
    let mut a = sin_latitude * sin_latitude +
        latitude1.cos() * latitude2.cos() * sin_longitude * sin_longitude;
    if a < 0.0 { a = 0.0; }
    if a > 1.0 { a = 1.0; }
    a
}

#[no_mangle]
pub extern "C" fn haversine_rust_variant(values: *const i64, length: usize) -> f64 {
    if !valid_coordinates(values, length) { return INVALID_RESULT; }
    let a = haversine_a(values);
    2.0 * a.asin().sqrt() * 6371000.0
}
