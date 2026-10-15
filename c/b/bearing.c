/* Return a spherical initial bearing in integer microdegrees. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MICRODEGREES_PER_DEGREE 1000000.0
#define DEGREES_PER_RADIAN 57.2957795130823208768
#define FULL_CIRCLE_MICRODEGREES INT64_C(360000000)

int64_t bearing(const int64_t *values, size_t length)
{
    if (values == NULL || length != 4) return -1;
    const int64_t latitude1_value = values[0];
    const int64_t longitude1_value = values[1];
    const int64_t latitude2_value = values[2];
    const int64_t longitude2_value = values[3];
    if (latitude1_value < -90000000 || latitude1_value > 90000000 ||
        latitude2_value < -90000000 || latitude2_value > 90000000 ||
        longitude1_value < -180000000 || longitude1_value > 180000000 ||
        longitude2_value < -180000000 || longitude2_value > 180000000 ||
        (latitude1_value == latitude2_value && longitude1_value == longitude2_value)) {
        return -1;
    }

    const double radians_per_microdegree = 0.000001 * (3.14159265358979323846 / 180.0);
    const double latitude1 = (double)latitude1_value * radians_per_microdegree;
    const double longitude1 = (double)longitude1_value * radians_per_microdegree;
    const double latitude2 = (double)latitude2_value * radians_per_microdegree;
    const double longitude2 = (double)longitude2_value * radians_per_microdegree;
    const double delta_longitude = longitude2 - longitude1;
    const double east = sin(delta_longitude) * cos(latitude2);
    const double north = cos(latitude1) * sin(latitude2) -
                         sin(latitude1) * cos(latitude2) * cos(delta_longitude);
    double degrees = atan2(east, north) * DEGREES_PER_RADIAN;
    if (degrees < 0.0) degrees += 360.0;
    const int64_t result = (int64_t)(degrees * MICRODEGREES_PER_DEGREE + 0.5);
    return result >= FULL_CIRCLE_MICRODEGREES ? 0 : result;
}
