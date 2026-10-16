const std = @import("std");
const PI_VALUE: f64 = 3.14159265358979323846264338327950288;

export fn geo_location(values: [*c]const f64, length: usize, output: [*c]f64, capacity: usize) i64 {
    if (values == null or length != 4) return -1;
    for (0..4) |i| if (values[i] != values[i] or values[i] > 1.0e100 or values[i] < -1.0e100) return -1;
    const lat1d, const lon1d, const lat2d, const lon2d = .{values[0], values[1], values[2], values[3]};
    if (lat1d < -90.0 or lat1d > 90.0 or lat2d < -90.0 or lat2d > 90.0 or
        lon1d < -180.0 or lon1d > 180.0 or lon2d < -180.0 or lon2d > 180.0) return -1;
    const factor = PI_VALUE / 180.0;
    const lat1, const lon1, const lat2, const lon2 = .{lat1d*factor, lon1d*factor, lat2d*factor, lon2d*factor};
    const diff_lat, const diff_lon = .{lat2-lat1, lon2-lon1};
    const sin_lat, const sin_lon = .{@sin(diff_lat/2.0), @sin(diff_lon/2.0)};
    const haversine = sin_lat*sin_lat + @cos(lat1)*@cos(lat2)*sin_lon*sin_lon;
    if (haversine < 0.0 or haversine > 1.0) return -1;
    if (output == null or capacity < 1) return -2;
    output[0] = 6371010.0 * (2.0 * std.math.atan2(@sqrt(haversine), @sqrt(1.0-haversine)));
    return 1;
}
