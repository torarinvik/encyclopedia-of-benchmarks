/// Return a spherical initial bearing in integer microdegrees.
export fn bearing(values: [*]const i64, length: usize) i64 {
    if (length != 4) return -1;
    const latitude1_value = values[0];
    const longitude1_value = values[1];
    const latitude2_value = values[2];
    const longitude2_value = values[3];
    if (latitude1_value < -90000000 or latitude1_value > 90000000 or
        latitude2_value < -90000000 or latitude2_value > 90000000 or
        longitude1_value < -180000000 or longitude1_value > 180000000 or
        longitude2_value < -180000000 or longitude2_value > 180000000 or
        (latitude1_value == latitude2_value and longitude1_value == longitude2_value)) return -1;

    const radians_per_microdegree = 0.000001 * (3.14159265358979323846 / 180.0);
    const latitude1 = @as(f64, @floatFromInt(latitude1_value)) * radians_per_microdegree;
    const longitude1 = @as(f64, @floatFromInt(longitude1_value)) * radians_per_microdegree;
    const latitude2 = @as(f64, @floatFromInt(latitude2_value)) * radians_per_microdegree;
    const longitude2 = @as(f64, @floatFromInt(longitude2_value)) * radians_per_microdegree;
    const delta_longitude = longitude2 - longitude1;
    const east = @sin(delta_longitude) * @cos(latitude2);
    const north = @cos(latitude1) * @sin(latitude2) -
        @sin(latitude1) * @cos(latitude2) * @cos(delta_longitude);
    var degrees = @atan2(east, north) * 57.2957795130823208768;
    if (degrees < 0.0) degrees += 360.0;
    const rounded = @as(i64, @intFromFloat(degrees * 1000000.0 + 0.5));
    return if (rounded >= 360000000) 0 else rounded;
}
