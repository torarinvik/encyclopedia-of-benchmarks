#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double kPi = 3.14159265358979323846;
constexpr double kWgs84A = 6378137.0;
constexpr double kWgs84B = 6356752.314245;

void geodetic_to_ecef(double lat_deg, double lon_deg, double alt_m,
                      double *x, double *y, double *z) {
    const double a_squared = kWgs84A * kWgs84A;
    const double b_squared = kWgs84B * kWgs84B;
    const double e_squared = 1.0 - (b_squared / a_squared);
    const double lat_rad = lat_deg * kPi / 180.0;
    const double lon_rad = lon_deg * kPi / 180.0;
    const double sin_lat = std::sin(lat_rad);
    const double cos_lat = std::cos(lat_rad);
    const double n_radius = kWgs84A / std::sqrt(1.0 - e_squared * sin_lat * sin_lat);
    *x = (n_radius + alt_m) * cos_lat * std::cos(lon_rad);
    *y = (n_radius + alt_m) * cos_lat * std::sin(lon_rad);
    *z = (n_radius * (1.0 - e_squared) + alt_m) * sin_lat;
}

void ecef_to_geodetic(double x_ecef, double y_ecef, double z_ecef,
                      double *lat_deg, double *lon_deg, double *alt_m) {
    const double a_squared = kWgs84A * kWgs84A;
    const double b_squared = kWgs84B * kWgs84B;
    const double e_squared = 1.0 - (b_squared / a_squared);
    const double ep_squared = (a_squared - b_squared) / b_squared;
    const double p = std::sqrt(x_ecef * x_ecef + y_ecef * y_ecef);
    if (p == 0.0) {
        *lon_deg = 0.0;
        *lat_deg = z_ecef > 0.0 ? 90.0 : -90.0;
        *alt_m = std::fabs(z_ecef) - kWgs84B;
        return;
    }
    const double theta = std::atan2(z_ecef * kWgs84A, p * kWgs84B);
    const double sin_theta = std::sin(theta);
    const double cos_theta = std::cos(theta);
    const double lon_rad = std::atan2(y_ecef, x_ecef);
    const double sin_theta_cubed = sin_theta * sin_theta * sin_theta;
    const double cos_theta_cubed = cos_theta * cos_theta * cos_theta;
    const double lat_rad = std::atan2(
        z_ecef + ep_squared * kWgs84B * sin_theta_cubed,
        p - e_squared * kWgs84A * cos_theta_cubed);
    const double sin_lat = std::sin(lat_rad);
    const double n_radius = kWgs84A / std::sqrt(1.0 - e_squared * sin_lat * sin_lat);
    *alt_m = (p / std::cos(lat_rad)) - n_radius;
    *lat_deg = lat_rad * 180.0 / kPi;
    *lon_deg = lon_rad * 180.0 / kPi;
}

void enu_to_ecef(double east, double north, double up,
                 double ref_lat_deg, double ref_lon_deg,
                 double *dx, double *dy, double *dz) {
    const double lat_rad = ref_lat_deg * kPi / 180.0;
    const double lon_rad = ref_lon_deg * kPi / 180.0;
    const double sin_lat = std::sin(lat_rad);
    const double cos_lat = std::cos(lat_rad);
    const double sin_lon = std::sin(lon_rad);
    const double cos_lon = std::cos(lon_rad);
    *dx = -sin_lon * east - sin_lat * cos_lon * north + cos_lat * cos_lon * up;
    *dy = cos_lon * east - sin_lat * sin_lon * north + cos_lat * sin_lon * up;
    *dz = cos_lat * north + sin_lat * up;
}
}  // namespace

extern "C" int64_t radar_target_calculation(const double *values, std::size_t length,
                                              double *output, std::size_t capacity) {
    if (values == nullptr || length != 6) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (!std::isfinite(values[i])) return -1;

    const double radar_lat = values[0];
    const double radar_lon = values[1];
    const double radar_alt = values[2];
    const double azimuth_deg = values[3];
    const double range_m = values[4];
    const double elevation_deg = values[5];
    if (radar_lat < -80.0 || radar_lat > 80.0 ||
        radar_lon < -180.0 || radar_lon > 180.0 ||
        radar_alt < -1000.0 || radar_alt > 10000.0 ||
        azimuth_deg < -360.0 || azimuth_deg > 360.0 ||
        range_m < 0.0 || range_m > 200000.0 ||
        elevation_deg < -30.0 || elevation_deg > 30.0) return -1;

    const double az_rad = azimuth_deg * kPi / 180.0;
    const double el_rad = elevation_deg * kPi / 180.0;
    const double east = range_m * std::cos(el_rad) * std::sin(az_rad);
    const double north = range_m * std::cos(el_rad) * std::cos(az_rad);
    const double up = range_m * std::sin(el_rad);
    double radar_x, radar_y, radar_z;
    geodetic_to_ecef(radar_lat, radar_lon, radar_alt, &radar_x, &radar_y, &radar_z);
    double dx, dy, dz;
    enu_to_ecef(east, north, up, radar_lat, radar_lon, &dx, &dy, &dz);
    double target_lat, target_lon, target_alt;
    ecef_to_geodetic(radar_x + dx, radar_y + dy, radar_z + dz,
                     &target_lat, &target_lon, &target_alt);

    if (output == nullptr || capacity < 3) return -2;
    output[0] = target_lat;
    output[1] = target_lon;
    output[2] = target_alt;
    return 3;
}
