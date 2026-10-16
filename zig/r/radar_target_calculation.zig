const std = @import("std");

const pi_value = 3.14159265358979323846;
const wgs84_a = 6378137.0;
const wgs84_b = 6356752.314245;

fn geodeticToEcef(lat_deg: f64, lon_deg: f64, alt_m: f64,
    x: *f64, y: *f64, z: *f64) void {
    const a_squared = wgs84_a * wgs84_a;
    const b_squared = wgs84_b * wgs84_b;
    const e_squared = 1.0 - (b_squared / a_squared);
    const lat_rad = lat_deg * pi_value / 180.0;
    const lon_rad = lon_deg * pi_value / 180.0;
    const sin_lat = @sin(lat_rad);
    const cos_lat = @cos(lat_rad);
    const n_radius = wgs84_a / @sqrt(1.0 - e_squared * sin_lat * sin_lat);
    x.* = (n_radius + alt_m) * cos_lat * @cos(lon_rad);
    y.* = (n_radius + alt_m) * cos_lat * @sin(lon_rad);
    z.* = (n_radius * (1.0 - e_squared) + alt_m) * sin_lat;
}

fn ecefToGeodetic(x_ecef: f64, y_ecef: f64, z_ecef: f64,
    lat_deg: *f64, lon_deg: *f64, alt_m: *f64) void {
    const a_squared = wgs84_a * wgs84_a;
    const b_squared = wgs84_b * wgs84_b;
    const e_squared = 1.0 - (b_squared / a_squared);
    const ep_squared = (a_squared - b_squared) / b_squared;
    const p = @sqrt(x_ecef * x_ecef + y_ecef * y_ecef);
    if (p == 0.0) {
        lon_deg.* = 0.0;
        lat_deg.* = if (z_ecef > 0.0) 90.0 else -90.0;
        alt_m.* = @abs(z_ecef) - wgs84_b;
        return;
    }
    const theta = @atan2(z_ecef * wgs84_a, p * wgs84_b);
    const sin_theta = @sin(theta);
    const cos_theta = @cos(theta);
    const lon_rad = @atan2(y_ecef, x_ecef);
    const sin_theta_cubed = sin_theta * sin_theta * sin_theta;
    const cos_theta_cubed = cos_theta * cos_theta * cos_theta;
    const lat_rad = @atan2(
        z_ecef + ep_squared * wgs84_b * sin_theta_cubed,
        p - e_squared * wgs84_a * cos_theta_cubed);
    const sin_lat = @sin(lat_rad);
    const n_radius = wgs84_a / @sqrt(1.0 - e_squared * sin_lat * sin_lat);
    alt_m.* = (p / @cos(lat_rad)) - n_radius;
    lat_deg.* = lat_rad * 180.0 / pi_value;
    lon_deg.* = lon_rad * 180.0 / pi_value;
}

fn enuToEcef(east: f64, north: f64, up: f64,
    ref_lat_deg: f64, ref_lon_deg: f64, dx: *f64, dy: *f64, dz: *f64) void {
    const lat_rad = ref_lat_deg * pi_value / 180.0;
    const lon_rad = ref_lon_deg * pi_value / 180.0;
    const sin_lat = @sin(lat_rad);
    const cos_lat = @cos(lat_rad);
    const sin_lon = @sin(lon_rad);
    const cos_lon = @cos(lon_rad);
    dx.* = -sin_lon * east - sin_lat * cos_lon * north + cos_lat * cos_lon * up;
    dy.* = cos_lon * east - sin_lat * sin_lon * north + cos_lat * sin_lon * up;
    dz.* = cos_lat * north + sin_lat * up;
}

export fn radar_target_calculation(values: [*c]const f64, length: usize,
    output: [*c]f64, capacity: usize) i64 {
    if (values == null or length != 6) return -1;
    for (0..6) |i| {
        if (!std.math.isFinite(values[i])) return -1;
    }
    const radar_lat = values[0];
    const radar_lon = values[1];
    const radar_alt = values[2];
    const azimuth_deg = values[3];
    const range_m = values[4];
    const elevation_deg = values[5];
    if (radar_lat < -80.0 or radar_lat > 80.0 or
        radar_lon < -180.0 or radar_lon > 180.0 or
        radar_alt < -1000.0 or radar_alt > 10000.0 or
        azimuth_deg < -360.0 or azimuth_deg > 360.0 or
        range_m < 0.0 or range_m > 200000.0 or
        elevation_deg < -30.0 or elevation_deg > 30.0) return -1;

    const az_rad = azimuth_deg * pi_value / 180.0;
    const el_rad = elevation_deg * pi_value / 180.0;
    const east = range_m * @cos(el_rad) * @sin(az_rad);
    const north = range_m * @cos(el_rad) * @cos(az_rad);
    const up = range_m * @sin(el_rad);
    var radar_x: f64 = 0.0;
    var radar_y: f64 = 0.0;
    var radar_z: f64 = 0.0;
    geodeticToEcef(radar_lat, radar_lon, radar_alt, &radar_x, &radar_y, &radar_z);
    var dx: f64 = 0.0;
    var dy: f64 = 0.0;
    var dz: f64 = 0.0;
    enuToEcef(east, north, up, radar_lat, radar_lon, &dx, &dy, &dz);
    var target_lat: f64 = 0.0;
    var target_lon: f64 = 0.0;
    var target_alt: f64 = 0.0;
    ecefToGeodetic(radar_x + dx, radar_y + dy, radar_z + dz,
        &target_lat, &target_lon, &target_alt);
    if (output == null or capacity < 3) return -2;
    output[0] = target_lat;
    output[1] = target_lon;
    output[2] = target_alt;
    return 3;
}
