#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define PI 3.14159265358979323846264338327950288

int64_t geo_location(const double *values, size_t length, double *output, size_t capacity) {
    if (values == NULL || length != 4) return -1;
    for (size_t i = 0; i < 4; ++i) if (!isfinite(values[i])) return -1;
    const double lat1d = values[0], lon1d = values[1];
    const double lat2d = values[2], lon2d = values[3];
    if (lat1d < -90.0 || lat1d > 90.0 || lat2d < -90.0 || lat2d > 90.0 ||
        lon1d < -180.0 || lon1d > 180.0 || lon2d < -180.0 || lon2d > 180.0) return -1;
    const double factor = PI / 180.0;
    const double lat1 = lat1d * factor, lon1 = lon1d * factor;
    const double lat2 = lat2d * factor, lon2 = lon2d * factor;
    const double diff_lat = lat2 - lat1, diff_lon = lon2 - lon1;
    const double sin_lat = sin(diff_lat / 2.0), sin_lon = sin(diff_lon / 2.0);
    const double haversine = sin_lat * sin_lat + cos(lat1) * cos(lat2) * sin_lon * sin_lon;
    if (haversine < 0.0 || haversine > 1.0) return -1;
    if (output == NULL || capacity < 1) return -2;
    output[0] = 6371010.0 * (2.0 * atan2(sqrt(haversine), sqrt(1.0 - haversine)));
    return 1;
}
