const INVALID_RESULT: f64 = -1.0e300;
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;

fn validCoordinates(values: [*]const i64, length: usize) bool {
    if (length != 4) return false;
    if (values[0] < -90000000 or values[0] > 90000000) return false;
    if (values[2] < -90000000 or values[2] > 90000000) return false;
    if (values[1] < -180000000 or values[1] > 180000000) return false;
    if (values[3] < -180000000 or values[3] > 180000000) return false;
    return true;
}

fn haversineA(values: [*]const i64) f64 {
    const radians_per_microdegree = PI_VALUE / 180000000.0;
    const latitude1 = @as(f64, @floatFromInt(values[0])) * radians_per_microdegree;
    const longitude1 = @as(f64, @floatFromInt(values[1])) * radians_per_microdegree;
    const latitude2 = @as(f64, @floatFromInt(values[2])) * radians_per_microdegree;
    const longitude2 = @as(f64, @floatFromInt(values[3])) * radians_per_microdegree;
    const delta_latitude = latitude2 - latitude1;
    const delta_longitude = longitude2 - longitude1;
    const sin_latitude = @sin(delta_latitude / 2.0);
    const sin_longitude = @sin(delta_longitude / 2.0);
    var a = sin_latitude * sin_latitude +
        @cos(latitude1) * @cos(latitude2) * sin_longitude * sin_longitude;
    if (a < 0.0) a = 0.0;
    if (a > 1.0) a = 1.0;
    return a;
}

export fn haversine_rust_variant(values: [*]const i64, length: usize) f64 {
    if (!validCoordinates(values, length)) return INVALID_RESULT;
    const a = haversineA(values);
    return 2.0 * @sqrt(@asin(a)) * 6371000.0;
}
