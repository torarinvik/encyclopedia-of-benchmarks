#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define PI_VALUE 3.14159265358979323846264338327950288

static int valid_coordinates(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return 0;
    if (values[0] < -90000000 || values[0] > 90000000) return 0;
    if (values[2] < -90000000 || values[2] > 90000000) return 0;
    if (values[1] < -180000000 || values[1] > 180000000) return 0;
    if (values[3] < -180000000 || values[3] > 180000000) return 0;
    return 1;
}

static double haversine_a(const int64_t *values)
{
    const double radians_per_microdegree = PI_VALUE / 180000000.0;
    const double latitude1 = (double)values[0] * radians_per_microdegree;
    const double longitude1 = (double)values[1] * radians_per_microdegree;
    const double latitude2 = (double)values[2] * radians_per_microdegree;
    const double longitude2 = (double)values[3] * radians_per_microdegree;
    const double delta_latitude = latitude2 - latitude1;
    const double delta_longitude = longitude2 - longitude1;
    const double sin_latitude = sin(delta_latitude / 2.0);
    const double sin_longitude = sin(delta_longitude / 2.0);
    double a = sin_latitude * sin_latitude +
        cos(latitude1) * cos(latitude2) * sin_longitude * sin_longitude;
    if (a < 0.0) a = 0.0;
    if (a > 1.0) a = 1.0;
    return a;
}

double haversine_distance(const int64_t *values, size_t length)
{
    if (!valid_coordinates(values, length)) return INVALID_RESULT;
    const double a = haversine_a(values);
    return 2.0 * atan2(sqrt(a), sqrt(1.0 - a)) * 6371.0;
}
