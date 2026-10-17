#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define PI 3.14159265358979323846264338327950288
#define EARTH_RADIUS 6371000.0

int64_t rhumb_distance(const double *input, size_t input_length,
                       double *output, size_t output_capacity) {
    if (input == NULL || input_length != 4) return -1;
    const double lat1 = input[0], long1 = input[1], lat2 = input[2], long2 = input[3];
    if (!isfinite(lat1) || !isfinite(long1) || !isfinite(lat2) || !isfinite(long2) ||
        lat1 < -85.0 || lat1 > 85.0 || lat2 < -85.0 || lat2 > 85.0 ||
        long1 < -180.0 || long1 > 180.0 || long2 < -180.0 || long2 > 180.0) return -1;
    const double phi1 = lat1 * PI / 180.0;
    const double phi2 = lat2 * PI / 180.0;
    const double del_phi = phi2 - phi1;
    double del_lambda = (long2 - long1) * PI / 180.0;
    if (del_lambda > PI) del_lambda -= 2.0 * PI;
    else if (del_lambda < -PI) del_lambda += 2.0 * PI;
    const double del_psi = log(tan(phi2 / 2.0 + PI / 4.0) / tan(phi1 / 2.0 + PI / 4.0));
    const double q = fabs(del_psi) > 1e-12 ? del_phi / del_psi : cos(phi1);
    const double distance = sqrt(pow(del_phi, 2.0) + pow(q * del_lambda, 2.0)) * EARTH_RADIUS;
    if (output == NULL || output_capacity < 1) return -2;
    output[0] = distance;
    return 1;
}
