module radar_target_calculation;

extern fn double sqrt(double value);
extern fn double sin(double value);
extern fn double cos(double value);
extern fn double atan2(double y, double x);
extern fn double fabs(double value);

const double PI = 3.14159265358979323846;
const double WGS84_A = 6378137.0;
const double WGS84_B = 6356752.314245;

fn void geodetic_to_ecef(double lat_deg, double lon_deg, double alt_m,
                         double* x, double* y, double* z) {
    double a_squared = WGS84_A * WGS84_A;
    double b_squared = WGS84_B * WGS84_B;
    double e_squared = 1.0 - (b_squared / a_squared);
    double lat_rad = lat_deg * PI / 180.0;
    double lon_rad = lon_deg * PI / 180.0;
    double sin_lat = sin(lat_rad);
    double cos_lat = cos(lat_rad);
    double n_radius = WGS84_A / sqrt(1.0 - e_squared * sin_lat * sin_lat);
    *x = (n_radius + alt_m) * cos_lat * cos(lon_rad);
    *y = (n_radius + alt_m) * cos_lat * sin(lon_rad);
    *z = (n_radius * (1.0 - e_squared) + alt_m) * sin_lat;
}

fn void ecef_to_geodetic(double x_ecef, double y_ecef, double z_ecef,
                         double* lat_deg, double* lon_deg, double* alt_m) {
    double a_squared = WGS84_A * WGS84_A;
    double b_squared = WGS84_B * WGS84_B;
    double e_squared = 1.0 - (b_squared / a_squared);
    double ep_squared = (a_squared - b_squared) / b_squared;
    double p = sqrt(x_ecef * x_ecef + y_ecef * y_ecef);
    if (p == 0.0) {
        *lon_deg = 0.0;
        *lat_deg = z_ecef > 0.0 ? 90.0 : -90.0;
        *alt_m = fabs(z_ecef) - WGS84_B;
        return;
    }
    double theta = atan2(z_ecef * WGS84_A, p * WGS84_B);
    double sin_theta = sin(theta);
    double cos_theta = cos(theta);
    double lon_rad = atan2(y_ecef, x_ecef);
    double sin_theta_cubed = sin_theta * sin_theta * sin_theta;
    double cos_theta_cubed = cos_theta * cos_theta * cos_theta;
    double lat_rad = atan2(z_ecef + ep_squared * WGS84_B * sin_theta_cubed,
        p - e_squared * WGS84_A * cos_theta_cubed);
    double sin_lat = sin(lat_rad);
    double n_radius = WGS84_A / sqrt(1.0 - e_squared * sin_lat * sin_lat);
    *alt_m = (p / cos(lat_rad)) - n_radius;
    *lat_deg = lat_rad * 180.0 / PI;
    *lon_deg = lon_rad * 180.0 / PI;
}

fn void enu_to_ecef(double east, double north, double up,
                    double ref_lat_deg, double ref_lon_deg,
                    double* dx, double* dy, double* dz) {
    double lat_rad = ref_lat_deg * PI / 180.0;
    double lon_rad = ref_lon_deg * PI / 180.0;
    double sin_lat = sin(lat_rad);
    double cos_lat = cos(lat_rad);
    double sin_lon = sin(lon_rad);
    double cos_lon = cos(lon_rad);
    *dx = -sin_lon * east - sin_lat * cos_lon * north + cos_lat * cos_lon * up;
    *dy = cos_lon * east - sin_lat * sin_lon * north + cos_lat * sin_lon * up;
    *dz = cos_lat * north + sin_lat * up;
}

fn long radar_target_calculation(double* values, usz length,
                                 double* output, usz capacity) @export("radar_target_calculation") {
    if (values == null || length != 6) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] != values[i] || values[i] < -1.0e100 || values[i] > 1.0e100) return -1;
    }
    double radar_lat = values[0];
    double radar_lon = values[1];
    double radar_alt = values[2];
    double azimuth_deg = values[3];
    double range_m = values[4];
    double elevation_deg = values[5];
    if (radar_lat < -80.0 || radar_lat > 80.0 || radar_lon < -180.0 || radar_lon > 180.0 ||
        radar_alt < -1000.0 || radar_alt > 10000.0 || azimuth_deg < -360.0 || azimuth_deg > 360.0 ||
        range_m < 0.0 || range_m > 200000.0 || elevation_deg < -30.0 || elevation_deg > 30.0) return -1;

    double az_rad = azimuth_deg * PI / 180.0;
    double el_rad = elevation_deg * PI / 180.0;
    double east = range_m * cos(el_rad) * sin(az_rad);
    double north = range_m * cos(el_rad) * cos(az_rad);
    double up = range_m * sin(el_rad);
    double radar_x, radar_y, radar_z;
    geodetic_to_ecef(radar_lat, radar_lon, radar_alt, &radar_x, &radar_y, &radar_z);
    double dx, dy, dz;
    enu_to_ecef(east, north, up, radar_lat, radar_lon, &dx, &dy, &dz);
    double target_lat, target_lon, target_alt;
    ecef_to_geodetic(radar_x + dx, radar_y + dy, radar_z + dz,
        &target_lat, &target_lon, &target_alt);
    if (output == null || capacity < 3) return -2;
    output[0] = target_lat;
    output[1] = target_lon;
    output[2] = target_alt;
    return 3;
}
