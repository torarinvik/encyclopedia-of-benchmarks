#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define PI 3.14159265358979323846264338327950288

int64_t rhumb_bearing(const double *input, size_t input_length,
                      double *output, size_t output_capacity) {
    if (input == NULL || input_length != 4) return -1;
    const double lat1 = input[0], long1 = input[1], lat2 = input[2], long2 = input[3];
    if (!isfinite(lat1) || !isfinite(long1) || !isfinite(lat2) || !isfinite(long2) ||
        lat1 < -85.0 || lat1 > 85.0 || lat2 < -85.0 || lat2 > 85.0 ||
        long1 < -180.0 || long1 > 180.0 || long2 < -180.0 || long2 > 180.0) return -1;

    const double phi1 = lat1 * PI / 180.0;
    const double phi2 = lat2 * PI / 180.0;
    double del_lambda = (long2 - long1) * PI / 180.0;
    if (del_lambda > PI) del_lambda -= 2.0 * PI;
    else if (del_lambda < -PI) del_lambda += 2.0 * PI;
    const double del_psi = log(tan(phi2 / 2.0 + PI / 4.0) / tan(phi1 / 2.0 + PI / 4.0));
    const double bearing = atan2(del_lambda, del_psi) * 180.0 / PI;
    const double bearing_plus_360 = bearing + 360.0;
    const double normalized = bearing_plus_360 - floor(bearing_plus_360 / 360.0) * 360.0;

    if (output == NULL || output_capacity < 1) return -2;
    output[0] = normalized;
    return 1;
}
