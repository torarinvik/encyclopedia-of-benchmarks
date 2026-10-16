#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t geo_location(const double *values, std::size_t length,
                                      double *output, std::size_t capacity) {
    if (values == nullptr || length != 4) return -1;
    for (std::size_t i = 0; i < 4; ++i) if (!std::isfinite(values[i])) return -1;
    const double lat1d = values[0], lon1d = values[1];
    const double lat2d = values[2], lon2d = values[3];
    if (lat1d < -90.0 || lat1d > 90.0 || lat2d < -90.0 || lat2d > 90.0 ||
        lon1d < -180.0 || lon1d > 180.0 || lon2d < -180.0 || lon2d > 180.0) return -1;
    constexpr double pi = 3.14159265358979323846264338327950288;
    const double factor = pi / 180.0;
    const double lat1 = lat1d * factor, lon1 = lon1d * factor;
    const double lat2 = lat2d * factor, lon2 = lon2d * factor;
    const double diff_lat = lat2 - lat1, diff_lon = lon2 - lon1;
    const double sin_lat = std::sin(diff_lat / 2.0), sin_lon = std::sin(diff_lon / 2.0);
    const double haversine = sin_lat * sin_lat + std::cos(lat1) * std::cos(lat2) * sin_lon * sin_lon;
    if (haversine < 0.0 || haversine > 1.0) return -1;
    if (output == nullptr || capacity < 1) return -2;
    output[0] = 6371010.0 * (2.0 * std::atan2(std::sqrt(haversine), std::sqrt(1.0 - haversine)));
    return 1;
}
