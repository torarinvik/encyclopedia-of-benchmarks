module haversine_rust_variant

import math

const invalid_result = -1.0e300
const pi_value = 3.14159265358979323846264338327950288

fn valid_coordinates(values &i64, length usize) bool {
    if length != 4 { return false }
    if values == nil { return false }
    if unsafe { values[0] } < -90000000 || unsafe { values[0] } > 90000000 { return false }
    if unsafe { values[2] } < -90000000 || unsafe { values[2] } > 90000000 { return false }
    if unsafe { values[1] } < -180000000 || unsafe { values[1] } > 180000000 { return false }
    if unsafe { values[3] } < -180000000 || unsafe { values[3] } > 180000000 { return false }
    return true
}

fn haversine_a(values &i64) f64 {
    radians_per_microdegree := pi_value / 180000000.0
    latitude1 := f64(unsafe { values[0] }) * radians_per_microdegree
    longitude1 := f64(unsafe { values[1] }) * radians_per_microdegree
    latitude2 := f64(unsafe { values[2] }) * radians_per_microdegree
    longitude2 := f64(unsafe { values[3] }) * radians_per_microdegree
    delta_latitude := latitude2 - latitude1
    delta_longitude := longitude2 - longitude1
    sin_latitude := math.sin(delta_latitude / 2.0)
    sin_longitude := math.sin(delta_longitude / 2.0)
    mut a := sin_latitude * sin_latitude +
        math.cos(latitude1) * math.cos(latitude2) * sin_longitude * sin_longitude
    if a < 0.0 { a = 0.0 }
    if a > 1.0 { a = 1.0 }
    return a
}

@[export: 'haversine_rust_variant']
pub fn haversine_rust_variant(values &i64, length usize) f64 {
    if !valid_coordinates(values, length) { return invalid_result }
    a := haversine_a(values)
    return 2.0 * math.sqrt(math.asin(a)) * 6371000.0
}
