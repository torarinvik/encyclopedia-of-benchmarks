package haversine_rust_variant

import "core:c"
import "core:math"

INVALID_RESULT :: -1.0e300
PI_VALUE :: 3.14159265358979323846264338327950288

valid_coordinates :: proc(values: [^]i64, length: c.size_t) -> bool {
    if values == nil || length != 4 do return false
    if values[0] < -90000000 || values[0] > 90000000 do return false
    if values[2] < -90000000 || values[2] > 90000000 do return false
    if values[1] < -180000000 || values[1] > 180000000 do return false
    if values[3] < -180000000 || values[3] > 180000000 do return false
    return true
}

haversine_a :: proc(values: [^]i64) -> f64 {
    radians_per_microdegree := PI_VALUE / 180000000.0
    latitude1 := f64(values[0]) * radians_per_microdegree
    longitude1 := f64(values[1]) * radians_per_microdegree
    latitude2 := f64(values[2]) * radians_per_microdegree
    longitude2 := f64(values[3]) * radians_per_microdegree
    delta_latitude := latitude2 - latitude1
    delta_longitude := longitude2 - longitude1
    sin_latitude := math.sin(delta_latitude / 2.0)
    sin_longitude := math.sin(delta_longitude / 2.0)
    a := sin_latitude * sin_latitude +
        math.cos(latitude1) * math.cos(latitude2) * sin_longitude * sin_longitude
    if a < 0.0 do a = 0.0
    if a > 1.0 do a = 1.0
    return a
}

@(export)
haversine_rust_variant :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if !valid_coordinates(values, length) do return INVALID_RESULT
    a := haversine_a(values)
    return 2.0 * math.sqrt_f64(math.asin(a)) * 6371000.0
}
