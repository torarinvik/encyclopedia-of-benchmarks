const PI: f64 = 3.14159265358979323846;
const WGS84_A: f64 = 6378137.0;
const WGS84_B: f64 = 6356752.314245;

fn geodetic_to_ecef(lat_deg: f64, lon_deg: f64, alt_m: f64) -> (f64, f64, f64) {
    let a_squared = WGS84_A * WGS84_A;
    let b_squared = WGS84_B * WGS84_B;
    let e_squared = 1.0 - (b_squared / a_squared);
    let lat_rad = lat_deg * PI / 180.0;
    let lon_rad = lon_deg * PI / 180.0;
    let sin_lat = lat_rad.sin();
    let cos_lat = lat_rad.cos();
    let n_radius = WGS84_A / (1.0 - e_squared * sin_lat * sin_lat).sqrt();
    let x = (n_radius + alt_m) * cos_lat * lon_rad.cos();
    let y = (n_radius + alt_m) * cos_lat * lon_rad.sin();
    let z = (n_radius * (1.0 - e_squared) + alt_m) * sin_lat;
    (x, y, z)
}

fn ecef_to_geodetic(x_ecef: f64, y_ecef: f64, z_ecef: f64) -> (f64, f64, f64) {
    let a_squared = WGS84_A * WGS84_A;
    let b_squared = WGS84_B * WGS84_B;
    let e_squared = 1.0 - (b_squared / a_squared);
    let ep_squared = (a_squared - b_squared) / b_squared;
    let p = (x_ecef * x_ecef + y_ecef * y_ecef).sqrt();
    if p == 0.0 {
        let lon_deg = 0.0;
        let lat_deg = if z_ecef > 0.0 { 90.0 } else { -90.0 };
        let alt_m = z_ecef.abs() - WGS84_B;
        return (lat_deg, lon_deg, alt_m);
    }

    let theta = (z_ecef * WGS84_A).atan2(p * WGS84_B);
    let sin_theta = theta.sin();
    let cos_theta = theta.cos();
    let lon_rad = y_ecef.atan2(x_ecef);
    let sin_theta_cubed = sin_theta * sin_theta * sin_theta;
    let cos_theta_cubed = cos_theta * cos_theta * cos_theta;
    let lat_rad = (z_ecef + ep_squared * WGS84_B * sin_theta_cubed)
        .atan2(p - e_squared * WGS84_A * cos_theta_cubed);
    let sin_lat = lat_rad.sin();
    let n_radius = WGS84_A / (1.0 - e_squared * sin_lat * sin_lat).sqrt();
    let alt_m = (p / lat_rad.cos()) - n_radius;
    (lat_rad * 180.0 / PI, lon_rad * 180.0 / PI, alt_m)
}

fn enu_to_ecef(east: f64, north: f64, up: f64,
               ref_lat_deg: f64, ref_lon_deg: f64) -> (f64, f64, f64) {
    let lat_rad = ref_lat_deg * PI / 180.0;
    let lon_rad = ref_lon_deg * PI / 180.0;
    let sin_lat = lat_rad.sin();
    let cos_lat = lat_rad.cos();
    let sin_lon = lon_rad.sin();
    let cos_lon = lon_rad.cos();
    let dx = -sin_lon * east - sin_lat * cos_lon * north + cos_lat * cos_lon * up;
    let dy = cos_lon * east - sin_lat * sin_lon * north + cos_lat * sin_lon * up;
    let dz = cos_lat * north + sin_lat * up;
    (dx, dy, dz)
}

#[no_mangle]
pub unsafe extern "C" fn radar_target_calculation(
    values: *const f64,
    length: usize,
    output: *mut f64,
    capacity: usize,
) -> i64 {
    if values.is_null() || length != 6 {
        return -1;
    }
    let values = std::slice::from_raw_parts(values, length);
    if values.iter().any(|value| !value.is_finite()) {
        return -1;
    }
    let radar_lat = values[0];
    let radar_lon = values[1];
    let radar_alt = values[2];
    let azimuth_deg = values[3];
    let range_m = values[4];
    let elevation_deg = values[5];
    if !(-80.0..=80.0).contains(&radar_lat)
        || !(-180.0..=180.0).contains(&radar_lon)
        || !(-1000.0..=10000.0).contains(&radar_alt)
        || !(-360.0..=360.0).contains(&azimuth_deg)
        || !(0.0..=200000.0).contains(&range_m)
        || !(-30.0..=30.0).contains(&elevation_deg)
    {
        return -1;
    }

    let az_rad = azimuth_deg * PI / 180.0;
    let el_rad = elevation_deg * PI / 180.0;
    let east = range_m * el_rad.cos() * az_rad.sin();
    let north = range_m * el_rad.cos() * az_rad.cos();
    let up = range_m * el_rad.sin();
    let (radar_x, radar_y, radar_z) = geodetic_to_ecef(radar_lat, radar_lon, radar_alt);
    let (dx, dy, dz) = enu_to_ecef(east, north, up, radar_lat, radar_lon);
    let (target_lat, target_lon, target_alt) =
        ecef_to_geodetic(radar_x + dx, radar_y + dy, radar_z + dz);

    if output.is_null() || capacity < 3 {
        return -2;
    }
    *output.add(0) = target_lat;
    *output.add(1) = target_lon;
    *output.add(2) = target_alt;
    3
}
